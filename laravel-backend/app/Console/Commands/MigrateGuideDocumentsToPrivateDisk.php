<?php

namespace App\Console\Commands;

use App\Models\GuideApplication;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class MigrateGuideDocumentsToPrivateDisk extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'guide-documents:migrate-to-private {--execute : Actually move files and update DB rows (default is a dry run)}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Moves guide_documents/* (license/NIC/selfie photos) from the public disk to the private disk and renames them to UUIDs, closing the unauthenticated-static-file-exposure gap. Run once after deploying the GuideDocumentUploadController fix — existing uploads made before that fix are still sitting on the public disk until this runs.';

    public function handle(): int
    {
        $execute = (bool) $this->option('execute');

        if (!$execute) {
            $this->warn('DRY RUN — no files will be moved and no DB rows updated. Pass --execute to actually migrate.');
        }

        $publicDisk = Storage::disk('public');
        $privateDisk = Storage::disk('local');

        if (!$publicDisk->exists('guide_documents')) {
            $this->info('No guide_documents directory found on the public disk — nothing to migrate.');
            return 0;
        }

        $uidDirs = $publicDisk->directories('guide_documents');
        $this->info('Found ' . count($uidDirs) . ' guide UID director' . (count($uidDirs) === 1 ? 'y' : 'ies') . ' under guide_documents/ on the public disk.');

        $migrated = 0;
        $failed = 0;

        foreach ($uidDirs as $uidDir) {
            $uid = basename($uidDir);
            $files = $publicDisk->files($uidDir);

            // Figure out which doc_type each old filename represents
            // ({timestamp}_{doctype}.ext) so the application record's URL
            // columns can be updated to the new download route.
            $application = GuideApplication::where('user_id', $uid)->first();

            foreach ($files as $oldPath) {
                $filename = basename($oldPath);
                $ext = pathinfo($filename, PATHINFO_EXTENSION);
                $docType = null;
                foreach (['license', 'nic', 'selfie'] as $type) {
                    if (str_contains($filename, "_{$type}")) {
                        $docType = $type;
                        break;
                    }
                }

                $newFilename = Str::uuid()->toString() . ($docType ? "_{$docType}" : '') . '.' . $ext;
                $newRelativePath = "guide_documents/{$uid}/{$newFilename}";

                $this->line(($execute ? 'Migrating: ' : '[dry-run] Would migrate: ') . "{$oldPath} -> (private) {$newRelativePath}");

                if (!$execute) {
                    continue;
                }

                try {
                    $contents = $publicDisk->get($oldPath);
                    $privateDisk->put($newRelativePath, $contents);

                    $newUrl = route('admin.guide-documents.download', ['uid' => $uid, 'filename' => $newFilename]);

                    if ($application && $docType) {
                        $column = "{$docType}_doc_url";
                        if (in_array($column, $application->getFillable(), true) || array_key_exists($column, $application->getAttributes())) {
                            $application->{$column} = $newUrl;
                        }
                    }

                    $publicDisk->delete($oldPath);
                    $migrated++;
                } catch (\Exception $e) {
                    $this->error("Failed to migrate {$oldPath}: " . $e->getMessage());
                    $failed++;
                }
            }

            if ($execute && $application && $application->isDirty()) {
                $application->save();
            }

            if ($execute && count($publicDisk->files($uidDir)) === 0) {
                $publicDisk->deleteDirectory($uidDir);
            }
        }

        if ($execute) {
            $this->info("Migrated {$migrated} file(s)." . ($failed > 0 ? " {$failed} failed — see errors above." : ''));
            $this->warn('Remember: any already-shared/cached public URLs (e.g. in old admin-panel browser tabs, email links, or a CDN cache) will now 404 — this is expected, they were the exposure being closed.');
        } else {
            $this->info('Dry run complete. Re-run with --execute to actually migrate.');
        }

        return $failed > 0 ? 1 : 0;
    }
}
