Docker image with alpine + Python3 + TensolFlow + Jupyter
=========================================================

This provides a Docker image with

- Alpine
- Python3
- TensolFlow
- Juptyer

This is heavily inspired by https://hub.docker.com/r/enakai00/jupyter_tensorflow/
Docker image.

## Supported tags and respective `Dockerfile` links

- [`1.3.0`, `latest`](https://github.com/tatsushid/docker-alpine-py3-tensorflow-jupyter/blob/master/Dockerfile)

## How to use this image

Please run the following

```shellsession
docker run -itd -p 8888:8888 -e PASSWORD=foobar tatsushid/alpine-py3-tensorflow-jupyter
```

and access to `http://{docker host}:8888/`. It opens Jupyter's login panel so
please enter the password which you specified as `PASSWORD` environment value

This repository also provides Docker Compose example so you can boot a
container of this image by running

```shellsession
docker-compose up
```

in `docker_compose_example` directory.

## License
This alpine-py3-tensorflow-jupyter Docker image is under MIT License. See the
[LICENSE][license] file for details.

[license]: https://github.com/tatsushid/docker-alpine-py3-tensorflow-jupyter/blob/master/LICENSE
