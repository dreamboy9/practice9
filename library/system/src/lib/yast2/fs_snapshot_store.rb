# ***************************************************************************
#
# Copyright (c) 2015 SUSE LLC
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail,
# you may find current contact information at www.novell.com
#
# ***************************************************************************

require "yast"

Yast.import "FileUtils"

module Yast2
  # Goal of this module is to provide easy to use api to store id of pre
  # snapshots, so post snapshots can be then easy to make.
  module FsSnapshotStore
    # Stores pre snapshot with given id and purpose
    # @param[String] purpose of snapshot like "upgrade"
    # @raise[RuntimeError] if writing to file failed
    def self.save(purpose, snapshot_id)
      ensure_snapshot_store_path
      result = Yast::SCR.Write(
        Yast::Path.new(".target.string"),
        snapshot_path(purpose),
        snapshot_id.to_s
      )

      raise "Failed to write Pre Snapshot id for #{purpose} to store. See logs." unless result
    end

    # Loads id of pre snapshot for given purpose
    # @param[String] purpose of snapshot like "upgrade"
    # @raise[RuntimeError] if writing to file failed
    # @return[Fixnum]
    def self.load(purpose)
      content = Yast::SCR.Read(
        Yast::Path.new(".target.string"),
        snapshot_path(purpose)
      )

      raise "Failed to read Pre Snapshot id for #{purpose} from store. See logs." if !content || content !~ /^\d+$/

      content.to_i
    end

    # Cleans store content of given purpose
    def self.clean(purpose)
      Yast::SCR.Execute(Yast::Path.new(".target.remove"), snapshot_path(purpose))
    end

    STORE_PATH = "/var/lib/YaST2".freeze
    # Directory to save the snapshots IDs
    #
    # @return [String]
    def self.snapshot_store_path
      Yast.import "Stage"
      return STORE_PATH unless Yast::Stage.initial || !Yast::WFM.scr_chrooted?

      Yast.import "Installation"
      ::File.join(Yast::Installation.destdir, STORE_PATH)
    end
    private_class_method :snapshot_store_path

    # Path where is stored given purpose
    def self.snapshot_path(purpose)
      File.join(snapshot_store_path, "pre_snapshot_#{purpose}.id")
    end
    private_class_method :snapshot_path

    # Ensures that the snapshots base path exists
    def self.ensure_snapshot_store_path
      return if Yast::FileUtils.Exists(snapshot_store_path)

      Yast::SCR.Execute(Yast::Path.new(".target.mkdir"), snapshot_store_path)
    end
    private_class_method :ensure_snapshot_store_path
  end
end
