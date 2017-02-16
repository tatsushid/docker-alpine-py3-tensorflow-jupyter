Notebook Directory
==================

If you put files into this directory and boot a container by docker-compose
with an example `docker-compose.yml` in a parent directory, all files in this
directory are shared with the container and placed at `/root/notebook/my_notes`
in the container. It can be also used from Jupyter as `my_notes`.
