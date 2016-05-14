module Rack::API::Pagination
  protected

  def api_paginate(collection)
    paginated_set = collection.page(pagination_page).per(pagination_per_page(collection))
    is_paginated = set_pagination_headers(paginated_set)

    paginated_set
  end

  def set_pagination_headers(scope)
    pages = build_pagination_pages(scope)
    links = build_pagination_links(pages, scope)

    headers['Link'] = links.join(', ') if links.any?
    headers['X-Total-Count'] = "#{scope.total_count}"

    links.any?
  end

  private

  def build_pagination_links(pages, scope)
    base_url = request.url.split('?').first
    per_page = pagination_per_page(scope)

    pages.map do |rel, page|
      page_params = request.query_parameters.merge({ page: page, per_page: per_page })
      '<%s?%s>; rel="%s"' % [ base_url, page_params.to_param, rel ]
    end
  end

  def build_pagination_pages(scope)
    pages = {}
    pages[:first] = 1 if scope.total_pages > 1 && scope.current_page > 1
    pages[:prev] = scope.current_page - 1 if scope.current_page > 1
    pages[:next] = scope.current_page + 1 if scope.current_page < scope.total_pages
    pages[:last] = scope.total_pages if scope.total_pages > 1 && scope.current_page < scope.total_pages
    pages
  end

  # The requested pagination page, if any.
  def pagination_page
    page = params[:page].to_i
    page = 1 if page == 0
    page
  end

  # The requested number of resources per paginated page, if any.
  def pagination_per_page(assoc)
    per_page = params[:per_page].to_i
    per_page = if per_page == 0
      assoc.base_class.instance_variable_get('@_default_per_page') || 0
    end

    per_page = if per_page == 0
      Kaminari.config.default_per_page
    end

    per_page
  end
end