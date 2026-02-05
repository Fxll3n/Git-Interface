@tool
extends Control

@onready var file_tree: Tree = %FileList
@onready var commit_message: TextEdit = %CommitMessage
@onready var status_log: RichTextLabel = %Status
@onready var refresh_timer: Timer = Timer.new()

var git_executable = "git"
var repo_path = ""

func _ready():
	repo_path = ProjectSettings.globalize_path("res://")
	refresh_status()
	
	%FetchChanges.pressed.connect(refresh_status)
	%Commit.pressed.connect(_on_commit_pressed)
	%Pull.pressed.connect(_on_pull_pressed)
	%Push.pressed.connect(_on_push_pressed)
	%Credit.meta_clicked.connect(
		func(meta):
			OS.shell_open(str(meta))
	)
	
	# Update periodicly.
	add_child(refresh_timer)
	refresh_timer.one_shot = true
	refresh_timer.start(10)
	refresh_timer.timeout.connect(
		func():
			refresh_status()
			refresh_timer.start(10)
	)


func execute_git_command_sync(args: Array) -> Dictionary:
	var output = []

	var exit_code = OS.execute(git_executable, args, output, true, false)
	
	return {
		"exit_code": exit_code,
		"output": "\n".join(output)
	}

func execute_git_command_async(args: Array, callback: Callable):
	var script_path = "res://.godot/git_temp_command.sh" if OS.get_name() != "Windows" else "res://.godot/git_temp_command.bat"
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	
	if OS.get_name() == "Windows":
		file.store_string("@echo off\ncd /d \"" + repo_path + "\"\ngit " + " ".join(args))
	else:
		file.store_string("#!/bin/bash\ncd \"" + repo_path + "\"\ngit " + " ".join(args))
	file.close()
	
	if OS.get_name() != "Windows":
		OS.execute("chmod", ["+x", ProjectSettings.globalize_path(script_path)])
	
	# New thread so that Editor doesn't freeze when awaiting command results
	var thread = Thread.new()
	thread.start(_run_git_async.bind(script_path, callback))
	#thread.wait_to_finish()
	#thread.free()

func _run_git_async(script_path: String, callback: Callable):
	var output = []
	var exec_path = ProjectSettings.globalize_path(script_path)
	var exit_code = OS.execute(exec_path if OS.get_name() != "Windows" else "cmd.exe", 
		[] if OS.get_name() != "Windows" else ["/c", exec_path], 
		output, true, false)
	
	var result = {
		"exit_code": exit_code,
		"output": "\n".join(output)
	}
	
	# Call the callback on the main thread
	callback.call_deferred(result)

func refresh_status():
	var result = execute_git_command_sync(["status", "--porcelain"])
	
	if result.exit_code != 0:
		status_log.text = "[color=red][b]Error[/b][/color]: Not a git repository or git not found"
		return
	
	# Parse and display changes
	file_tree.clear()
	var root = file_tree.create_item()
	
	for line in result.output.split("\n"):
		if line.strip_edges() == "":
			continue
		
		var status = line.substr(0, 2)
		var file_path = line.substr(3)
		
		var item = file_tree.create_item(root)
		item.set_text(0, get_status_icon(status) + " " + file_path)
		item.set_metadata(0, {"file": file_path, "status": status})
	
	# Update status log
	var branch_result = execute_git_command_sync(["branch", "--show-current"])
	status_log.text = "[b]Branch[/b]: " + branch_result.output.strip_edges()

func get_status_icon(status: String) -> String:
	match status.strip_edges():
		"M", " M": return "[M]"
		"A", " A": return "[A]"
		"D", " D": return "[D]"
		"??": return "[?]"
		_: return "[*]"

func _on_commit_pressed():
	var message = commit_message.text.strip_edges()
	commit_message.text = ""
	if message == "":
		status_log.text = "[color=red][b]Error[/b][/color]: Commit message cannot be empty"
		return
	
	# Stage all changes
	var stage_result = execute_git_command_sync(["add", "-A"])
	if stage_result.exit_code != 0:
		status_log.text = "[color=red][b]Error[/b][/color] staging files:\n" + stage_result.output
		return
	
	# Commit
	var commit_result = execute_git_command_sync(["commit", "-m", message])
	status_log.text = commit_result.output
	
	if commit_result.exit_code == 0:
		refresh_status()

func _on_pull_pressed():
	status_log.text = "Pulling... (this may take a moment)"
	%Pull.disabled = true
	
	execute_git_command_async(["pull"], func(result):
		status_log.text = result.output if result.output != "" else "Pull completed"
		%Pull.disabled = false
		refresh_status()
	)

func _on_push_pressed():
	status_log.text = "Pushing... (this may take a moment)"
	%Push.disabled = true
	
	execute_git_command_async(["push"], func(result):
		status_log.text = result.output if result.output != "" else "Push completed"
		%Push.disabled = false
		refresh_status()
	)
