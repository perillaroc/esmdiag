module EsmDiag
  class Dataflow
    include DataflowDSL

    attr_reader :datasets

    def initialize
      metric = self.class.to_s.gsub(/EsmDiag::Dataflow_/, '')
      eval "@datasets = @@datasets_#{metric}"
      @datasets.each do |comp, tags|
        tags.each do |tag, dataset|
          if not dataset.root
            CLI.report_error "No #{comp} in model_data_info!" if not ConfigManager.model_data_info.has_key? comp
            CLI.report_error "No #{tag} in model_data_info->#{comp}!" if not ConfigManager.model_data_info[comp].has_key? tag
            if ConfigManager.model_data_info[comp].has_key? tag and ConfigManager.model_data_info[comp][tag].has_key? :root
              dataset.root = File.expand_path ConfigManager.model_data_info[comp][tag][:root]
            elsif ConfigManager.model_data_info[comp].has_key? :root
              dataset.root = File.expand_path ConfigManager.model_data_info[comp][:root]
            elsif ConfigManager.model_data_info.has_key? :root
              dataset.root = File.expand_path ConfigManager.model_data_info.root
            end
            dataset.pattern = ConfigManager.model_data_info[comp][tag][:pattern]
          end
          dataset.data_list = "#{dataset.root}/#{dataset.pattern}" if not dataset.data_list
          dataset.variables.each_key do |var|
            dataset.variables[var][:pipelines] = [ '' ]
          end
        end
      end
      EsmDiag.attached_variables.each do |comp, vars|
        selected_data = Dir.glob(@datasets[comp].values.first.data_list).first
        dataset = Dataset.new
        dataset.data_list = selected_data
        dataset.extract *vars
        @datasets[comp][:fixed] = dataset
      end
    end

    def run metric
      @datasets.each do |comp, tags|
        tags.each do |tag, dataset|
          dataset.variables.each do |var, actions|
            actions.each do |action, options|
              next if not Actions.respond_to? action
              Actions.send(action, comp, dataset, metric, tag, var, options)
            end
          end
        end
      end
    end
  end
end
