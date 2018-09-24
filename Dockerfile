FROM centos:7
ARG host_docker_version="17.09.0-ce"
ARG hadolint_version="v1.10.4"
ARG user_id
ARG group_id
COPY perso.repo /etc/yum.repos.d/perso.repo
RUN chown root:root /etc/yum.repos.d/perso.repo && \
    chmod 644 /etc/yum.repos.d/perso.repo && \
    rm -f /etc/yum.repos.d/CentOS-*
RUN yum -y remove docker \
        docker-common \
        docker-selinux \
        docker-engine && \
    yum -y install wget \
	  sudo \
	  git \
	  iptables \
          procps \
	  xz.x86_64 \
	  wget	\
	  python
RUN  http_proxy="proxy" ; https_proxy="proxy" ; export http_proxy https_proxy  && \ 
  wget "https://download.docker.com/linux/static/stable/x86_64/docker-${host_docker_version}.tgz"  && \
  mv "docker-${host_docker_version}.tgz" docker.tgz && \
  tar xzvf docker.tgz && \
  mv docker/docker /usr/local/bin && \  
  rm -r docker docker.tgz && \
  chmod +x /usr/local/bin/docker
RUN chmod 755 /opt/check_modified_files.sh && \
    chmod 755 /opt/calculate_tag.sh && \
    http_proxy="proxy" ; https_proxy="proxy" ; export http_proxy https_proxy  && \
    wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/download/${hadolint_version}/hadolint-Linux-x86_64 && \
    chmod 755 /usr/local/bin/hadolint
COPY hadolint.yaml /etc/hadolint.yaml
ENV XDG_CONFIG_HOME=/etc
RUN groupadd -g ${group_id} jenkins-slave && \
    groupadd docker && \
    useradd jenkins-slave -u ${user_id} -g jenkins-slave --shell /bin/bash --create-home && \
    usermod -a -G docker jenkins-slave && \
    /bin/bash -c "sudo echo '%jenkins-slave        ALL=(ALL)  NOPASSWD: ALL' >>/etc/sudoers "
ENV PATH="usr/local/bin:${PATH}"
