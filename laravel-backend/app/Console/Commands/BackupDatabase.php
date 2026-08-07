<?php

namespace App\Console\Commands;

use App\Services\DiscordAlertService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Symfony\Component\Process\Process;

class BackupDatabase extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'db:backup';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Dumps the MySQL database to storage/app/backups (gzip), prunes dumps older than 14 days, and optionally pushes to S3 if AWS_* credentials are configured.';

    private const RETENTION_DAYS = 14;

    public function handle(DiscordAlertService $discord): int
    {
        $connection = config('database.connections.mysql');
        $database = $connection['database'];
        $timestamp = now()->format('Y-m-d_His');
        $filename = "backups/{$database}-{$timestamp}.sql.gz";
        $disk = Storage::disk('local');

        $fullPath = $disk->path($filename);
        $dir = dirname($fullPath);
        if (!is_dir($dir)) {
            mkdir($dir, 0755, true);
        }

        $dumpCommand = sprintf(
            'mysqldump --host=%s --port=%s --user=%s %s %s | gzip > %s',
            escapeshellarg($connection['host']),
            escapeshellarg((string) $connection['port']),
            escapeshellarg($connection['username']),
            $connection['password'] !== '' ? '--password=' . escapeshellarg($connection['password']) : '',
            escapeshellarg($database),
            escapeshellarg($fullPath)
        );

        $process = Process::fromShellCommandline($dumpCommand);
        $process->setTimeout(600);
        $process->run();

        if (!$process->isSuccessful() || !file_exists($fullPath) || filesize($fullPath) === 0) {
            $error = $process->getErrorOutput() ?: 'mysqldump produced no output file or an empty file.';
            Log::error('db:backup failed', ['error' => $error]);
            $discord->send("Database backup FAILED: {$error}", 'error');
            $this->error("Backup failed: {$error}");
            if (file_exists($fullPath)) {
                unlink($fullPath);
            }
            return 1;
        }

        $this->info("Backup written: {$filename} (" . round(filesize($fullPath) / 1024, 1) . ' KB)');
        Log::info('db:backup succeeded', ['file' => $filename, 'size_bytes' => filesize($fullPath)]);

        $this->pushToS3IfConfigured($filename, $discord);
        $this->pruneOldBackups($disk);

        return 0;
    }

    private function pushToS3IfConfigured(string $filename, DiscordAlertService $discord): void
    {
        if (empty(config('filesystems.disks.s3.key')) || empty(config('filesystems.disks.s3.bucket'))) {
            $this->info('S3 not configured — skipping off-site push (local backup only).');
            return;
        }

        try {
            $localDisk = Storage::disk('local');
            Storage::disk('s3')->put($filename, $localDisk->get($filename));
            $this->info('Backup pushed to S3.');
        } catch (\Exception $e) {
            Log::error('db:backup: S3 push failed', ['error' => $e->getMessage()]);
            $discord->send("Database backup succeeded locally, but the S3 off-site push failed: {$e->getMessage()}", 'warning');
        }
    }

    private function pruneOldBackups($disk): void
    {
        $cutoff = now()->subDays(self::RETENTION_DAYS)->timestamp;
        $pruned = 0;

        foreach ($disk->files('backups') as $file) {
            if ($disk->lastModified($file) < $cutoff) {
                $disk->delete($file);
                $pruned++;
            }
        }

        if ($pruned > 0) {
            $this->info("Pruned {$pruned} backup(s) older than " . self::RETENTION_DAYS . ' days.');
        }
    }
}
