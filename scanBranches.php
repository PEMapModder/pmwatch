<?php

$last = json_decode(file_get_contents("last.json"));
$data = array_filter(json_decode(file_get_contents("php://stdin")), function($ev) use($last){
	if(intval($ev->id) <= $last->lastEvent) return false;
	if($ev->type === "PushEvent"){
		return true;
	}
	if($ev->type === "PullRequestEvent"){
		if($ev->payload->action === "opened"){
			return true;
		}
	}
	return false;
});

$branches = [];
$max = $last->lastEvent;
foreach($data as $event){
	$max = (int) max($max, (int) $event->id);
	if($event->type === "PushEvent"){
		$branch = explode("/", $event->payload->ref)[2];
		$sha = $event->payload->head;
		if(!isset($branches[$branch])) $branches[$branch] = [
			"sha" => $sha,
			"time" => time(),
			"trigger" => $event->actor->login,
			"title" => $event->payload->commits[0]->message
		];
	}elseif($event->type === "PullRequestEvent"){
		$head = $event->payload->pull_request->head;
		$ref = $head->ref;
		$sha = $head->sha;
		$id = $event->payload->pull_request->number;
		if(!isset($branches["pr:" . $id])){
			$branches["pr:" . $id] = [
				"sha" => $sha,
				"time" => time(),
				"trigger" => $event->actor->login,
				"title" => $event->payload->pull_request->title,
				"remote" => $head->repo->clone_url,
				"id" => $id,
				"ref" => $ref
			];
		}
	}
}

$last->lastEvent = $max;
$last->lastRun = time();
foreach($branches as $branch => $data){
	$last->versions->{$branch} = $data;
}
file_put_contents("last.json", json_encode($last, JSON_PRETTY_PRINT));
foreach($branches as $branch => $data){
	$sha = $data["sha"];
	if(isset($data["remote"])) echo "pr:" . $data["id"] . ":" . str_replace(":", ";", $data["remote"]) . ":$sha";
	else echo "$branch:$sha";
	echo PHP_EOL;
}

