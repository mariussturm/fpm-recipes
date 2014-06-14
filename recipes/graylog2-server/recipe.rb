class Graylog2Server < FPM::Cookery::Recipe
  description 'Graylog2 server'

  name     'graylog2-server'
  version  '0.20.3'
  revision 1
  homepage 'http://graylog2.org/'
  arch     'all'

  source "https://github.com/Graylog2/graylog2-server/releases/download/#{version}/graylog2-server-#{version}.tgz"
  sha256 'a1cb64b1b6a0626d94f7a6c6e64e9e645aa3d798e5317390ccd7a96be3884599'

  maintainer 'TORCH GmbH <hello@torch.sh>'
  vendor     'torch'
  license    'GPLv3'

  config_files '/etc/graylog2.conf',
               '/etc/graylog2/server/log4j.xml'

  platforms [:ubuntu, :debian] do
    section 'net'
    depends 'openjdk-7-jre-headless', 'uuid-runtime'

    config_files '/etc/default/graylog2-server'

    post_install "files/#{platform}/post-install"
    post_uninstall "files/#{platform}/post-uninstall"
  end

  platforms [:ubuntu] do
    config_files '/etc/init/graylog2-server.conf'
  end

  platforms [:debian] do
    config_files '/etc/init.d/graylog2-server',
                 '/etc/logrotate.d/graylog2-server'
  end

  platforms [:centos] do
    depends 'java-1.7.0-openjdk', 'util-linux-ng'

    config_files '/etc/init.d/graylog2-server',
                 '/etc/sysconfig/graylog2-server'

    post_install 'files/centos/post-install'
    pre_uninstall 'files/centos/pre-uninstall'
  end

  def build
    patch(workdir('patches/graylog2-server.conf.patch'))
  end

  def install
    etc.install 'graylog2.conf.example', 'graylog2.conf'
    etc('graylog2/server').install file('log4j.xml')

    case FPM::Cookery::Facts.platform
    when :ubuntu
      etc('init').install osfile('upstart.conf'), 'graylog2-server.conf'
      etc('default').install osfile('default'), 'graylog2-server'
    when :debian
      etc('init.d').install osfile('init.d'), 'graylog2-server'
      etc('init.d/graylog2-server').chmod(0755)
      etc('default').install osfile('default'), 'graylog2-server'
      etc('logrotate.d').install osfile('logrotate'), 'graylog2-server'
    when :centos
      etc('init.d').install osfile('init.d'), 'graylog2-server'
      etc('init.d/graylog2-server').chmod(0755)
      etc('sysconfig').install osfile('sysconfig'), 'graylog2-server'
    end

    share('graylog2-server').install 'graylog2-server.jar'

    # Create all plugin directories.
    %w(filters outputs inputs initializers transports alarm_callbacks).each do |dir|
      share("graylog2-server/plugin/#{dir}").mkpath
    end
  end

  private

  def osfile(name)
    workdir(File.join('files', FPM::Cookery::Facts.platform.to_s, name))
  end

  def file(name)
    workdir(File.join('files', name))
  end
end
