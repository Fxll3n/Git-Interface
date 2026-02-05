@tool
extends Control

@onready var file_tree: Tree = %FileList
@onready var commit_message: TextEdit = %CommitMessage
@onready var status_log: RichTextLabel = %Status

var git_executable = "git"
var repo_path = ""

func _ready():
	repo_path = ProjectSettings.globalize_path("res://")
	refresh_status()
	
	# Connect buttons
	%FetchChanges.pressed.connect(refresh_status)
	%Commit.pressed.connect(_on_commit_pressed)
	%Pull.pressed.connect(_on_pull_pressed)
	%Push.pressed.connect(_on_push_pressed)

func execute_git_command_sync(args: Array) -> Dictionary:
	var output = []
	# Use working directory
	var exit_code = OS.execute(git_executable, args, output, true, false)
	
	return {
		"exit_code": exit_code,
		"output": "\n".join(output)
	}

# For potentially long operations (push, pull, fetch)
func execute_git_command_async(args: Array, callback: Callable):
	# Create a temporary script to handle the process
	var script_path = "res://.godot/git_temp_command.sh" if OS.get_name() != "Windows" else "res://.godot/git_temp_command.bat"
	var file = FileAccess.open(script_path, FileAccess.WRITE)
	
	if OS.get_name() == "Windows":
		file.store_string("@echo off\ncd /d \"" + repo_path + "\"\ngit " + " ".join(args))
	else:
		file.store_string("#!/bin/bash\ncd \"" + repo_path + "\"\ngit " + " ".join(args))
	file.close()
	
	# Make executable on Unix
	if OS.get_name() != "Windows":
		OS.execute("chmod", ["+x", ProjectSettings.globalize_path(script_path)])
	
	# Create a thread to run the process
	var thread = Thread.new()
	thread.start(_run_git_async.bind(script_path, callback))

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
		status_log.text = "Error: Not a git repository or git not found"
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
	status_log.text = "Branch: " + branch_result.output.strip_edges()

func get_status_icon(status: String) -> String:
	match status.strip_edges():
		"M", " M": return "[M]"
		"A", " A": return "[A]"
		"D", " D": return "[D]"
		"??": return "[?]"
		_: return "[*]"

func _on_commit_pressed():
	var message = commit_message.text.strip_edges()
	if message == "":
		status_log.text = "Error: Commit message cannot be empty"
		return
	
	# Stage all changes
	var stage_result = execute_git_command_sync(["add", "-A"])
	if stage_result.exit_code != 0:
		status_log.text = "Error staging files:\n" + stage_result.output
		return
	
	# Commit
	var commit_result = execute_git_command_sync(["commit", "-m", message])
	status_log.text = commit_result.output
	
	if commit_result.exit_code == 0:
		commit_message.text = ""
		refresh_status()

func _on_pull_pressed():
	status_log.text = "Pulling... (this may take a moment)"
	$Toolbar/PullBtn.disabled = true
	
	execute_git_command_async(["pull"], func(result):
		status_log.text = result.output if result.output != "" else "Pull completed"
		$Toolbar/PullBtn.disabled = false
		refresh_status()
	)

func _on_push_pressed():
	status_log.text = "Pushing... (this may take a moment)"
	$Toolbar/PushBtn.disabled = true
	
	execute_git_command_async(["push"], func(result):
		status_log.text = result.output if result.output != "" else "Push completed"
		$Toolbar/PushBtn.disabled = false
		refresh_status()
	)
