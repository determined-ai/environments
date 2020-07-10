# libnss\_determined

A plugin to the name switch service part of glibc.  This plugin is meant to be
built/installed in a Docker container during the build process.

See the [glibc documentation](https://gnu.org/software/libc/manual/html_node/NSS-Module-Function-Internals.html).

## How Determined Uses the Plugin

We can't edit a Docker container's `/etc/passwd`, `/etc/shadow`, or
`/etc/group` at runtime, but we can install this plugin at runtime as a file
overlay.  Conceptually, this plugin lets us embed files at runtime (like
`/run/determined/etc/passwd`) to safely and non-invasively extend the real
`/etc/passwd` in the Docker container.

The reason that we would need to inject users into a container is to make
programs that query the container's list of users (notably `sshd`) behave
nicely when running non-root containers.  This is a requisite for non-root
distributed training and non-root shells to work.

If a custom image does not contain our plugin, but the owner of the custom
image still wants to use non-root containers, the owner of the custom image is
responsible for embedding users in the image either at build time (by
prebuilding users into a container) or at runtime (by bind-mounting sockets to
connect to an AD user system into the container, for instance).

## Including the Plugin In a Custom Image

The easiest way to include the plugin is to copy the entire `libnss_determined`
directory to your `docker build` directory and include the relevant lines
directly from Determined's `Dockerfile.gpu`, for example.

### Manually Building the Plugin

Run `make libnss_determined.so.2`.

### Manually Installing the Plugin

Run `make install`, which will copy `libnss_determined.so.2` to `/lib`.

### Enabling The Plugin

Enable the plugin by appending a `determined` entry to each of the `passwd`,
`shadow`, and `group` lines of  `/etc/nsswitch.conf`.  See `man nsswitch.conf`
for details.  This will tell to glibc to call into our plugin whenever it
queries the `passwd`, `shadow`, or `group` databases.

You can verify that it is working by running `getent passwd`, `getent shadow`,
and `getent group`.

### Troubleshooting

Enable debug output by setting the `LIBNSS_DETERMINED_DEBUG` environment
variable to `1` when running programs that will query the plugin:

```
LIBNSS_DETERMINED_DEBUG=1 getent passwd
```

### Manually Testing the Plugin

Run `make test`.

Testing includes making calls to `docker build` and `docker run`, so it likely
won't work from within a container, unless you have configured
Docker-in-Docker.
