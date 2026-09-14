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
        $now = Carbon::parse('2026-09-14T12:00:00+05:30');

        $this->assertTrue(SubscriptionController::hasInvalidExpiry(null, $now));
        $this->assertTrue(SubscriptionController::hasInvalidExpiry('', $now));
        $this->assertTrue(SubscriptionController::hasInvalidExpiry('not-a-date', $now));
        $this->assertTrue(SubscriptionController::hasInvalidExpiry($now->copy()->subSecond()->toIso8601String(), $now));
        $this->assertTrue(SubscriptionController::hasInvalidExpiry($now->toIso8601String(), $now));
        $this->assertFalse(SubscriptionController::hasInvalidExpiry($now->copy()->addSecond()->toIso8601String(), $now));
    }
}
