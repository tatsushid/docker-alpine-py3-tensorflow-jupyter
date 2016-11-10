FROM alpine:3.4

ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV LOCAL_RESOURCES 2048,.5,1.0

ENV GLIBC_VERSION 2.23-r3
ENV BAZEL_VERSION 0.4.0
ENV LAPACK_VERSION 3.6.1
ENV TENSORFLOW_VERSION 0.11.0rc2

RUN apk add --no-cache python3 freetype libgfortran libpng libjpeg-turbo imagemagick graphviz
RUN apk add --no-cache --virtual=.build-deps \
        bash \
        ca-certificates \
        cmake \
        curl \
        freetype-dev \
        g++ \
        gfortran \
        libjpeg-turbo-dev \
        libpng-dev \
        linux-headers \
        make \
        musl-dev \
        openjdk8 \
        perl \
        python3-dev \
        rsync \
        sed \
        swig \
        zip \
    && : build and install blas and lapack libraries. numpy requires them \
    && cd /tmp \
    && curl -SL http://www.netlib.org/lapack/lapack-${LAPACK_VERSION}.tgz \
        | tar xzf - \
    && cd lapack-${LAPACK_VERSION} \
    && sed -e 's/^OPTS.*/OPTS     = -O2 -m64 -mtune=generic -fPIC/' \
        -e 's/^NOOPT.*/NOOPT    = -O0 -m64 -mtune=generic -fPIC/' \
        -e 's/librefblas\.a/libblas.a/' \
            make.inc.example > make.inc \
    && make blaslib lapacklib \
    && cp -p libblas.a /usr/lib/ \
    && cp -p liblapack.a /usr/lib/ \
    && : \
    && : prepare for building TensorFlow. install glibc to build Bazel. \
    && : install numpy and wheel python module too \
    && cd /tmp \
    && : numpy requires xlocale.h but it is not provided by musl-libc so just copy it from locale.h \
    && $(cd /usr/include/ && ln -s locale.h xlocale.h) \
    && pip3 install --no-cache-dir numpy wheel \
    && curl -SLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/unreleased/glibc-${GLIBC_VERSION}.apk \
    && curl -SLo /etc/apk/keys/sgerrand.rsa.pub https://github.com/sgerrand/alpine-pkg-glibc/releases/download/unreleased/sgerrand.rsa.pub \
    && apk add --no-cache --virtual=.glibc glibc-${GLIBC_VERSION}.apk \
    && : \
    && : install Bazel to build TensorFlow \
    && curl -SL https://github.com/bazelbuild/bazel/archive/${BAZEL_VERSION}.tar.gz \
        | tar xzf - \
    && cd bazel-${BAZEL_VERSION} \
    && : add -fpermissive compiler option to avoid compilation failure \
    && sed -i -e '/"-std=c++0x"/{h;x;s//"-fpermissive"/;x;G}' tools/cpp/cc_configure.bzl \
    && bash compile.sh \
    && cp -p output/bazel /usr/bin/ \
    && : \
    && : build TensorFlow pip package \
    && cd /tmp \
    && curl -SL https://github.com/tensorflow/tensorflow/archive/v${TENSORFLOW_VERSION}.tar.gz \
        | tar xzf - \
    && cd tensorflow-${TENSORFLOW_VERSION} \
    && : add python symlink to avoid python detection error in configure \
    && $(cd /usr/bin && ln -s python3 python) \
    && echo | PYTHON_BIN_PATH=/usr/bin/python TF_NEED_GCP=0 TF_NEED_HDFS=0 TF_NEED_CUDA=0 bash configure \
    && : comment out 'testonly' to avoid compilation failure. it will be fixed in future version \
    && sed -i -e '/name = "construction_fails_op"/{N;s/testonly/#testonly/}' tensorflow/python/BUILD \
    && bazel build -c opt --local_resources ${LOCAL_RESOURCES} //tensorflow/tools/pip_package:build_pip_package \
    && ./bazel-bin/tensorflow/tools/pip_package/build_pip_package /tmp/tensorflow_pkg \
    && : \
    && : install python modules including TensorFlow \
    && cd \
    && pip3 install --no-cache-dir /tmp/tensorflow_pkg/tensorflow-${TENSORFLOW_VERSION}-py3-none-any.whl \
    && pip3 install --no-cache-dir pandas scipy jupyter \
    && pip3 install --no-cache-dir scikit-learn matplotlib Pillow \
    && pip3 install --no-cache-dir google-api-python-client \
    && : \
    && : clean up unneeded packages and files \
    && apk del .build-deps .glibc \
    && rm -f /etc/apk/keys/sgerrand.rsa.pub \
    && rm -f /usr/bin/bazel \
    && rm -rf /tmp/* /root/.cache

RUN jupyter notebook --generate-config \
    && sed -i -e "/c\.NotebookApp\.ip/a c.NotebookApp.ip = '*'" \
        -e "/c\.NotebookApp\.open_browser/a c.NotebookApp.open_browser = False" \
            /root/.jupyter/jupyter_notebook_config.py
RUN ipython profile create \
    && sed -i -e "/c\.InteractiveShellApp\.matplotlib/a c.InteractiveShellApp.matplotlib = 'inline'" \
            /root/.ipython/profile_default/ipython_config.py

ADD init.sh /usr/local/bin/init.sh
RUN chmod u+x /usr/local/bin/init.sh
EXPOSE 8888
CMD ["/usr/local/bin/init.sh"]
