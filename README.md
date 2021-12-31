# PowerShell-Multi-threading
PowerShell Multi-threading Example

Just an example of how to spin up multiple worker sub-processes (jobs) in powershell to get a batch of tasks done quicker by parallizing them.

As is, the script does nothing but sleep and echo out a bunch of words. 
It is intended to serve as the basis of a script that does a lot of work.

Note that due to the overhead of spinning up these jobs, the tasks should not be too small.
If there are many small tasks, consider pushing batches of small tasks to jobs.
