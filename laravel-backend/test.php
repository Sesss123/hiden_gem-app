<?php
$s = file_get_contents('d:\app ai\data\raw\Matara\osm_church.jsonl'); 
$s = preg_replace('/\}\s*\{/', '},{', $s); 
var_dump(json_decode($s, true));
echo json_last_error_msg() . "\n";
file_put_contents('test_out.json', $s);
