ARG BASE_IMAGE
FROM ${BASE_IMAGE}

USER root
COPY image.manifest /tmp/image.manifest
COPY sample-tool /usr/local/bin/sample-tool
COPY sample-helper /opt/runner-fixture/bin/sample-helper
ENV PATH=/opt/runner-fixture/bin:${PATH}
RUN chmod 0755 /usr/local/bin/sample-tool /opt/runner-fixture/bin/sample-helper \
 && . /usr/local/lib/runner/metadata.sh \
 && runner_metadata_materialize_derived_manifest /tmp/image.manifest
USER runner
