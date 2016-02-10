<?php

$last = json_decode(file_get_contents("last.json"));
$data = array_filter(json_decode(file_get_contents("php://stdin")), function($ev) use($last){
	return ((int) $ev->id) > $last->lastEvent and $ev->type === "PushEvent";
});

$branches = [];
$max = $last->lastEvent;
foreach($data as $event){
	$max = (int) max($max, (int) $event->id);
	$branch = explode("/", $event->payload->ref)[2];
	$sha = $event->payload->head;
	if(!isset($branches[$branch])) $branches[$branch] = [
		"sha" => $sha,
		"time" => time(),
		"trigger" => $event->actor->login
	];
}

$last->lastEvent = $max;
$last->lastRun = time();
foreach($branches as $branch => $data){
	$last->versions->{$branch} = $data;
}
file_put_contents("last.json", json_encode($last, JSON_PRETTY_PRINT));
foreach($branches as $branch => $data){
	$sha = $data["sha"];
	echo "$branch:$sha", PHP_EOL;
}

