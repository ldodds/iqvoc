# encoding: UTF-8

# Copyright 2011 innoQ Deutschland GmbH
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class SearchResultsController < ApplicationController
  skip_before_filter :require_user

  def index
    authorize! :read, Concept::Base # TODO: I think a :search right would be
    # better here because you're able to serach more than only concepts.

    self.class.prepare_basic_variables(self)

    # Map short params to their log representation
    {:t => :type, :q => :query, :l => :languages, :qt => :query_type, :c => :collection_origin}.each do |short, long|
      params[long] ||= params[short]
    end

    # Delete parameters which should not be included into generated urls (e.g.
    # in rdf views)
    request.query_parameters.delete("commit")
    request.query_parameters.delete("utf8")

    if params[:query]
      if params[:query].blank? && params[:collection_origin].blank?
        flash.now[:error] = I18n.t('txt.controllers.search_results.insufficient_data')
        render :action => 'index', :status => 422
        return
      end

      # Special treatment for the "nil language"
      params[:languages] << nil if params[:languages].is_a?(Array) && params[:languages].include?("none")

      # Decide whether to search a specific class or ALL classes
      unless params[:type] == 'all'
        unless type_class_index = Iqvoc.searchable_class_names.map(&:parameterize).index(params[:type].parameterize)
          raise "'#{params[:type]}' is not a valid / configured searchable class! Must be one of " + Iqvoc.searchable_class_names.join(', ')
        end
        @klass = Iqvoc.searchable_class_names[type_class_index].constantize
      end

      query_size = params[:query].split(/\r\n/).size

      # @klass is only available if we're going to search using a specific class
      # it's not available if we're searching within all classes
      if @klass
        if @klass.forces_multi_query? || (@klass.supports_multi_query? && query_size > 1)
          @multi_query = true
          @results = @klass.multi_query(params)
          # TODO Add a worst case limit here. E.g. when beeing on page 2 (per_page == 50)
          # every sub query has to return 100 object at most.
        else
          @multi_query = false
          @results = @klass.single_query(params)
        end
      else
        @multi_query = true
        logger.debug "Searching for all names"
        # all names (including collection labels)
        @results = Iqvoc.searchable_classes.
          select { |klass| (klass < Labeling::Base) }. # Search for Labelings only
        map { |klass| klass.single_query(params) }.
          flatten.uniq
        # TODO (Important!!): Remove this mess. This is totally equivalent to a
        # search in Labeling::Base except that this is a multi query (which
        # isn't a good idea at all).
        # We'll have to check all sub projects redefining the searchable classes
        # to include "Labeling::Base" because :all won't be contained in the
        # selectbox per default.
      end

      if @multi_query
        @results = Kaminari.paginate_array(@results)
        logger.debug("Using multi query mode")
      else
        logger.debug("Using single query mode")
      end

      @results = @results.page(params[:page]).per(Iqvoc.pagination[:search_results_per_page])

      respond_to do |format|
        format.html
        format.ttl { render('search_results/index.iqrdf') }
        format.rdf { render('search_results/index.iqrdf') }
      end

    end
  end

  def self.prepare_basic_variables(controller)
    langs = (Iqvoc.available_languages + Iqvoc::Concept.labeling_class_names.values.flatten).uniq.each_with_object({}) do |lang_sym, hsh|
      lang_sym ||= "none"
      hsh[lang_sym.to_s] = I18n.t("languages.#{lang_sym.to_s}", :default => lang_sym.to_s)
    end
    controller.instance_variable_set(:@available_languages, langs)

    collections = Iqvoc::Collection.base_class.includes(:pref_labels).all
    controller.instance_variable_set(:@collections, collections)
  end
  
end
