# encoding: UTF-8

class DMSF_helper
    def self.deep_folder_search(project, folderPath)
        return nil if folderPath == "."
        search_folder_with_path(project, nil, folderPath.split(File::SEPARATOR))
    end
  
    def self.search_folder_with_path(project, parent, path)
        folder = DmsfFolder.visible.where(:project_id => project.id, :dmsf_folder_id => parent, :title => path[0]).first

        return folder if path.length == 1
      
        search_folder_with_path(project, folder.id, path.drop(1))
    end
  
end
