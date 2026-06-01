# Task 09: Generate an SBOM for the container with curl

You are connected to the `lab-09` Kubernetes cluster.

A deployment named `fruits` in the namespace `salad` has three containers:

- `apple`;
- `banana`;
- `kiwi`.

One of these running containers has the package `curl` installed.

Identify which container has that package from the running containers, then create an SBOM SPDX JSON for that container's image.

Use the tarball archive for that image stored under `/root/ImageTarballs`.
Archive file names are normalized from image names by replacing `/` and `:` with `_`.

The `bom` command and its required dependencies are installed.

Save the SPDX JSON output in:

`~/bugged-fruit.spdx`

Save the container name in:

`~/bugged-container.txt`

Validate your answer:

sh ~/val.sh
