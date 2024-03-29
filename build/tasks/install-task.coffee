fs = require 'fs'
path = require 'path'
_ = require 'underscore-plus'
fs = require 'fs-plus'
runas = null

module.exports = (grunt) ->
  {cp, mkdir, rm} = require('./task-helpers')(grunt)

  grunt.registerTask 'install', 'Install the built application', ->
    installDir = grunt.config.get('atom.installDir')
    shellAppDir = grunt.config.get('atom.shellAppDir')

    if process.platform is 'win32'
      runas ?= require 'runas'
      copyFolder = path.resolve 'script', 'copy-folder.cmd'
      if runas('cmd', ['/c', copyFolder, shellAppDir, installDir], admin: true) isnt 0
        grunt.log.error("Failed to copy #{shellAppDir} to #{installDir}")

      createShortcut = path.resolve 'script', 'create-shortcut.cmd'
      runas('cmd', ['/c', createShortcut, path.join(installDir, 'arcus.exe'), 'Atom'])
    else if process.platform is 'darwin'
      rm installDir
      mkdir path.dirname(installDir)
      cp shellAppDir, installDir
    else
      binDir = path.join(installDir, 'bin')
      shareDir = path.join(installDir, 'share', 'arcus')

      iconName = path.join(shareDir,'resources','app','resources','indico.png')

      mkdir binDir
      cp 'atom.sh', path.join(binDir, 'arcus')
      rm shareDir
      mkdir path.dirname(shareDir)
      cp shellAppDir, shareDir

      # Create Atom.desktop if installation not in temporary folder
      tmpDir = if process.env.TMPDIR? then process.env.TMPDIR else '/tmp'
      if installDir.indexOf(tmpDir) isnt 0
        desktopFile = path.join('resources', 'linux', 'Atom.desktop.in')
        desktopInstallFile = path.join(installDir, 'share', 'applications', 'Atom.desktop')

        {description} = grunt.file.readJSON('package.json')
        iconName = path.join(shareDir, 'resources', 'app', 'resources', 'indico.png')
        installDir = path.join(installDir, '.') # To prevent "Exec=/usr/local//share/atom/atom"
        template = _.template(String(fs.readFileSync(desktopFile)))
        filled = template({description, installDir, iconName})

        grunt.file.write(desktopInstallFile, filled)

      # Create relative symbol link for apm.
      process.chdir(binDir)
      rm('apm')
      fs.symlinkSync(path.join('..', 'share', 'atom', 'resources', 'app', 'apm', 'node_modules', '.bin', 'apm'), 'apm')

      fs.chmodSync(path.join(shareDir, 'atom'), "755")
