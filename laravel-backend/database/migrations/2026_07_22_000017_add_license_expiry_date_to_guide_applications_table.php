<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * license_expiry_date is picked in guide_enrollment_screen.dart and sent by
 * GuideApplication.toJson() (lib/data/models/guide_application.dart), but
 * GuideApplicationController::submit had no validator rule, no fillable
 * entry, and no column for it — it was silently discarded on the MySQL side
 * (it only ever reached Firestore, via the app's own direct write). This
 * column brings the Laravel/MySQL side in line with what the app already
 * sends.
 */
return new class extends Migration
{
    public function up()
    {
        Schema::table('guide_applications', function (Blueprint $table) {
            $table->date('license_expiry_date')->nullable()->after('license_number');
        });
    }

    public function down()
    {
        Schema::table('guide_applications', function (Blueprint $table) {
            $table->dropColumn('license_expiry_date');
        });
    }
};
