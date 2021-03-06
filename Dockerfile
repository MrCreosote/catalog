FROM kbase/sdkbase2:latest AS build


COPY . /tmp/catalog
RUN cd /tmp/catalog && make deploy-service deploy-server-control-scripts

FROM kbase/kb_python:latest
# These ARGs values are passed in via the docker build command
ARG BUILD_DATE
ARG VCS_REF
ARG BRANCH

ENV KB_DEPLOYMENT_CONFIG "/kb/deployment/conf/deploy.cfg"

COPY --from=build /kb/deployment/lib/biokbase /kb/deployment/lib/biokbase
COPY --from=build /kb/deployment/services /kb/deployment/services
COPY --from=build /tmp/catalog/deployment/conf /kb/deployment/conf

SHELL ["/bin/bash", "-c"]
RUN source activate root && \
    conda install -c anaconda semantic_version pymongo=2.8 && \
    pip install docker && \
    ln -s /usr/lib/python2.7/plat-*/_sysconfigdata_nd.py /usr/lib/python2.7/

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-url="https://github.com/kbase/catalog.git" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.schema-version="1.0.0-rc1" \
      us.kbase.vcs-branch=$BRANCH \
      maintainer="Steve Chan sychan@lbl.gov"


ENTRYPOINT [ "/kb/deployment/bin/dockerize" ]

# Here are some default params passed to dockerize. They would typically
# be overidden by docker-compose at startup
CMD [ "-template", "/kb/deployment/conf/.templates/deploy.cfg.templ:/kb/deployment/conf/deploy.cfg", \
      "/kb/deployment/services/catalog/start_service" ]