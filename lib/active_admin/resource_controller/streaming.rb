require 'csv'

module ActiveAdmin
  class ResourceController < BaseController

    # This module overrides CSV responses to allow large data downloads.
    # Could be expanded to JSON and XML in the future.
    #
    module Streaming

      def index(arg=nil)
        super do |format|
          format.csv { stream_csv }
          yield(format) if block_given?
        end
      end

      protected

      def stream_resource(&block)
        headers['X-Accel-Buffering'] = 'no'
        headers['Cache-Control'] = 'no-cache'

        if ActiveAdmin.application.disable_streaming_in.include? Rails.env
          self.response_body = block['']
        else
          self.response_body = Enumerator.new &block
        end
      end

      def csv_filename
        "#{resource_collection_name.to_s.gsub('_', '-')}-#{Time.zone.now.to_date.to_s(:default)}.csv"
      end

      def stream_csv
        headers['Content-Disposition'] = %{attachment; filename="#{csv_filename}"}
        stream_resource &active_admin_config.csv_builder.method(:build).to_proc.curry[self]
      end

    end
  end
end
