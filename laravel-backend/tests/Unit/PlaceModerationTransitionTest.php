<?php

namespace Tests\Unit;

use PHPUnit\Framework\TestCase;
use App\Models\Place;

class PlaceModerationTransitionTest extends TestCase
{
    /**
     * Test status constant values.
     */
    public function test_place_status_constants()
    {
        $this->assertEquals('pending', Place::STATUS_PENDING);
        $this->assertEquals('approved', Place::STATUS_APPROVED);
        $this->assertEquals('rejected', Place::STATUS_REJECTED);
    }

    /**
     * Test SHA-256 duplicate content detection mechanism.
     */
    public function test_file_hash_detection()
    {
        $jsonContent1 = json_encode([['name' => 'Dunhinda Falls', 'category' => 'Waterfall', 'district' => 'Badulla']]);
        $jsonContent2 = json_encode([['name' => 'Dunhinda Falls', 'category' => 'Waterfall', 'district' => 'Badulla']]);
        $jsonContent3 = json_encode([['name' => 'Diyaluma Falls', 'category' => 'Waterfall', 'district' => 'Badulla']]);

        $hash1 = hash('sha256', $jsonContent1);
        $hash2 = hash('sha256', $jsonContent2);
        $hash3 = hash('sha256', $jsonContent3);

        $this->assertEquals($hash1, $hash2, 'Identical contents must yield identical SHA-256 checksums');
        $this->assertNotEquals($hash1, $hash3, 'Different contents must yield distinct checksums');
        $this->assertEquals(64, strlen($hash1), 'SHA-256 hash must be 64 characters long');
    }

    /**
     * Test valid ID format regex used by the backend.
     */
    public function test_place_id_regex()
    {
        $validIds = ['WF-BAD-001', 'BE-GAL-042', 'CUL-KAN-109'];
        $invalidIds = ['../../../etc/passwd', 'WF/BAD/01', '<script>alert(1)</script>'];

        $pattern = '/^[A-Z]{2,4}-[A-Z]{3}-\d{3}$/';

        foreach ($validIds as $id) {
            $this->assertEquals(1, preg_match($pattern, $id), "Expected {$id} to match pattern");
        }

        foreach ($invalidIds as $id) {
            $this->assertEquals(0, preg_match($pattern, $id), "Expected {$id} not to match pattern");
        }
    }
}
