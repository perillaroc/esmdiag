module ScriniumEsmDiag
  class Actions
    def self.anomaly_accepted_options
      { :delete_input => [ TrueClass, FalseClass ] }
    end

    def self.anomaly dataset, metric, tag, var, options
      ActionHelpers.start(dataset.variables[var][:pipelines], options).each do |status_pipeline|
        pipeline = status_pipeline.last
        if status_pipeline.first == :active
          input_file_name = ActionHelpers.create_file_name var, tag, pipeline
          pipeline << '.anomaly'
          output_file_name = ActionHelpers.create_file_name var, tag, pipeline
          if not Cache.already_generated? output_file_name
            case tag
            when :daily
              ScriniumEsmDiag.run "cdo --history ydaysub #{input_file_name} -ydaymean #{input_file_name} #{output_file_name}"
            when :monthly
              ScriniumEsmDiag.run "cdo --history ymonsub #{input_file_name} -ymonmean #{input_file_name} #{output_file_name}"
            end
            Cache.save_pipeline output_file_name
          end
        end
        dataset.variables[var][:pipelines] << pipeline
      end
    end
  end
end
