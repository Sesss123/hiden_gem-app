<?php

namespace Tests\Unit;

use PHPUnit\Framework\TestCase;
use App\Http\Controllers\Admin\SubscriptionController;
use Carbon\Carbon;

class SubscriptionIntegrityTest extends TestCase
{
    /**
     * Test allowed product/plan whitelist recognition.
     */
    public function test_whitelisted_plans_are_recognized()
    {
        $allowedPlans = array_keys(SubscriptionController::ALLOWED_PLANS);

        $this->assertContains('pro', $allowedPlans);
        $this->assertContains('elite', $allowedPlans);
        $this->assertContains('explorer', $allowedPlans);
        $this->assertContains('premium', $allowedPlans);
    }

    /**
     * Test mock plan and unknown plan detection.
     */
    public function test_mock_and_unknown_plans_are_flagged()
    {
        $allowedPlans = SubscriptionController::ALLOWED_PLANS;

        $testPlans = [
            'premium_mock_dev' => true,
            'test_plan_debug' => true,
            'unknown_custom' => true,
            'pro' => false,
            'elite' => false,
            'premium' => false,
        ];

        foreach ($testPlans as $plan => $expectedIsMock) {
            $isMockOrInvalid = !array_key_exists(strtolower(trim($plan)), $allowedPlans);
            $this->assertEquals(
                $expectedIsMock,
                $isMockOrInvalid,
                "Plan '{$plan}' expected mock/invalid to be " . ($expectedIsMock ? 'true' : 'false')
            );
        }
    }

    /**
     * Test expiration date calculation.
     */
    public function test_expired_subscription_detection()
    {
        $pastDate = Carbon::now()->subDays(5)->toIso8601String();
        $futureDate = Carbon::now()->addDays(30)->toIso8601String();

        $this->assertTrue(Carbon::parse($pastDate)->isPast());
        $this->assertFalse(Carbon::parse($futureDate)->isPast());
    }
}
