## Managing metric source

Do the following to manage the metrics source workflow:
* `make ecs-create # Create the metrics task`
* `make ecs-up # Run the metrics task with default prefix 'haggar'`
* `make ecs-down # Stop the metrics task`

To set a custom prefix for haggar use:
* `make ecs-up -e METRIC_ROOT=gonzo # Run the metrics task with custom prefix 'gonzo'`
