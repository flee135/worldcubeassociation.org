module ApplicationHelper
  def full_title(page_title='')
    base_title = WcaOnRails::Application.config.site_name
    if page_title.empty?
      base_title
    else
      page_title + " | " + base_title
    end
  end

  def bootstrap_class_for(flash_type)
    {
      success: "alert-success",
      danger: "alert-danger",
      warning: "alert-warning",
      info: "alert-info",

      # For devise
      notice: "alert-success",
      alert: "alert-danger",

      recaptcha_error: "alert-danger"
    }[flash_type.to_sym] || flash_type.to_s
  end

  def mail_to_wca_board
    mail_to "board@worldcubeassociation.org", "Board", target: "_blank"
  end

  def md(content, target_blank: false)
    if content.nil?
      return ""
    end

    options = {
      hard_wrap: true
    }

    if target_blank
      options[:link_attributes] = { target: "_blank" }
    end

    Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(options)).render(content).html_safe
  end

  def filename_to_url(filename)
    "/" + Pathname.new(File.absolute_path(filename)).relative_path_from(Rails.public_path).to_path
  end

  def anchorable(pretty_text)
    id = pretty_text.parameterize
    "<span id='#{id}' class='anchorable'>#{pretty_text} <a href='##{id}'><span class='glyphicon glyphicon-link'></span></a></span>".html_safe
  end

  WCA_EXCERPT_RADIUS = 50

  def wca_excerpt(html, phrase)
    text = ActiveSupport::Inflector.transliterate(strip_tags(html)) # TODO https://github.com/cubing/worldcubeassociation.org/issues/238
    excerpted = excerpt(text, phrase, radius: WCA_EXCERPT_RADIUS)
    # If nothing matches the given phrase, just return the beginning.
    if excerpted.blank?
      excerpted = truncate(text, length: WCA_EXCERPT_RADIUS)
    end
    wca_highlight(excerpted, phrase)
  end

  def wca_highlight(html, phrases, do_not_transliterate: false)
    if !do_not_transliterate
      text = ActiveSupport::Inflector.transliterate(strip_tags(html)) # TODO https://github.com/cubing/worldcubeassociation.org/issues/238
    else
      text = strip_tags(html)
    end
    highlight(text, phrases, highlighter: '<strong>\1</strong>')
  end

  def wca_omni_search
    text_field_tag nil, @omni_query, placeholder: "Search site", class: "form-control wca-autocomplete wca-autocomplete-omni wca-autocomplete-search wca-autocomplete-only_one wca-autocomplete-users_search wca-autocomplete-persons_table"
  end

  def wca_local_time(time)
    local_time(time, "%B %e, %Y %l:%M%P %Z")
  end

  # TODO - table-for turns out to be pretty slow, so we're rolling our own
  # table helper. Eventually we should get rid of all uses of wca_table_for.
  def wca_table(responsive: true, hover: true, striped: true, table_class: "", &block)
    table_classes = "table wca-results floatThead table-condensed table-greedy-last-column #{table_class}"
    if hover
      table_classes += " table-hover"
    end
    if striped
      table_classes += " table-striped"
    end

    content_tag :div, class: (responsive ? "table-responsive" : "") do
      content_tag :table, class: table_classes do
        block.call
      end
    end
  end

  def wca_selectable_table_for(records, options={}, &block)
    extra_table_class = options[:extra_table_class] + " selectable-rows"
    wca_table_for(records, extra_table_class: extra_table_class) do |table|
      table.column data: "", header: lambda { content_tag(:span) } do |record|
        check_box_tag "#{record.class.name.downcase}-#{record.id}", "1", false, class: "select-row-checkbox"
      end
      block.call(table)
    end
  end

  def wca_table_for(records, hover: true, striped: true, extra_table_class: "", &block)
    table_classes = "table wca-results floatThead table-condensed #{extra_table_class}"
    if hover
      table_classes += " table-hover"
    end
    if striped
      table_classes += " table-striped"
    end
    table_for_options = {
      table_html: {
        class: table_classes
      },
      header_column_html: {
        class: lambda { |column| column.name.to_s.gsub(/_/, '-') }
      },
      data_row_html: {
        class: lambda { |record|
          c = []
          if record.is_a?(Registration)
            if record.pending?
              c << "registration-pending"
            end
            if record.accepted?
              c << "registration-accepted"
            end
          end
          c
        }
      },
      data_column_html: {
        class: lambda do |record, column|
          c = [column.name.to_s.gsub(/_/, '-')]
          if column.name == :position && record.tied_previous
            c << "tied-previous"
          end
          c
        end
      },
    }

    content_tag :div, class: "table-responsive" do
      table_for records, table_for_options do |table|
        table.define :wca_id do |registration|
          if registration.personId
            render "shared/wca_id", wca_id: registration.wca_id
          end
        end
        table.define :wca_id_header do
          "WCA ID"
        end

        table.define :position
        table.define :position_header do
          "#"
        end

        table.define :countryId_header do
          "Citizen of"
        end

        table.define :delegates do |competition|
          wca_highlight competition.delegates.map(&:name).to_sentence, current_user.name, do_not_transliterate: true
        end
        table.define :delegates_header do
          "Delegate(s)"
        end

        table.define :organizers do |competition|
          wca_highlight competition.organizers.map(&:name).to_sentence, current_user.name, do_not_transliterate: true
        end
        table.define :organizers_header do
          "Organizer(s)"
        end

        (Event.all_official + Event.all_deprecated).each do |event|
          event_span = content_tag(:span, "",
            title: event.name,
            class: "cubing-icon icon-#{event.id}",
            data: {
              toggle: "tooltip",
              placement: "bottom",
              container: "body",
            },
          )
          table.define event.id do |registration|
            if registration.events.include?(event)
              event_span
            end
          end
          table.define "#{event.id}_header" do
            event_span
          end
        end

        block.call(table)

        # Add an extra empty column at the end to take up all the extra
        # horizontal space.
        table.column data: ""
      end
    end
  end

  def process_nav_items(nav_items)
    nav_items.each do |nav_item|
      nav_item[:children] = nav_item[:children] || []
      nav_item[:tiny_children] = nav_item[:tiny_children] || []
      process_nav_items(nav_item[:children])
      process_nav_items(nav_item[:tiny_children])
      nav_item[:active] = (nav_item[:is_active] && nav_item[:is_active].call) || (nav_item[:path] && current_page?(nav_item[:path])) || nav_item[:children].any? { |i| i[:active] } || nav_item[:tiny_children].any? { |i| i[:active] }
    end
    nav_items
  end

  def notifications_for_user(user)
    notifications = []
    # Be careful to not show a competition twice if we're both organizing and delegating it.
    unconfirmed_competitions = (user.delegated_competitions.where(isConfirmed: false) + user.organized_competitions.where(isConfirmed: false)).uniq &:id
    unconfirmed_competitions.each do |unconfirmed_competition|
      notifications << {
        text: "#{unconfirmed_competition.name} is not confirmed",
        url: edit_competition_path(unconfirmed_competition),
      }
    end
    if user.board_member?
      # Show board members:
      #  - Confirmed, but not visible competitions: They need to approve or reject
      #                                             these competitions.
      #  - Unconfirmed, but visible competitions: These competitions should be confirmed
      #                                           so people cannot change old competitions.
      Competition.where(isConfirmed: true, showAtAll: false).each do |competition|
        notifications << {
          text: "#{competition.name} is waiting to be announced",
          url: admin_edit_competition_path(competition),
        }
      end
      Competition.where(isConfirmed: false, showAtAll: true).each do |competition|
        notifications << {
          text: "#{competition.name} is visible, but unlocked",
          url: admin_edit_competition_path(competition),
        }
      end
    end

    if user.wca_id.blank?
      if user.unconfirmed_wca_id? && user.delegate_to_handle_wca_id_claim
        # The user has already claimed a WCA ID, let them know we're on it.
        notifications << {
          text: "Waiting for #{user.delegate_to_handle_wca_id_claim.name} to assign you WCA ID #{user.unconfirmed_wca_id}",
          url: profile_claim_wca_id_path,
        }
      else
        # Show users without WCA IDs how to claim a WCA ID for their account.
        notifications << {
          text: "Connect your WCA ID to your account!",
          url: profile_claim_wca_id_path,
        }
      end
    end

    # Show all the users who are waiting to have their WCA ID claims approved.
    # Note that it is possible for users who have not yet confirmed their accounts
    # to have claimed a WCA ID, as we support claiming a WCA ID as part of signing up
    # for an account. We don't want to bother delegates with these claims until
    # the user has confirmed their account, though, so filter out users with
    # confirmed_at=NULL.
    user.users_claiming_wca_id.where.not(confirmed_at: nil).each do |user_claiming_wca_id|
      notifications << {
        text: "#{user_claiming_wca_id.email} has claimed WCA ID #{user_claiming_wca_id.unconfirmed_wca_id}",
        url: edit_user_path(user_claiming_wca_id.id, anchor: "wca_id"),
      }
    end

    if user.cannot_register_for_competition_reasons.length > 0
      notifications << {
        text: "Your profile is incomplete. You will not be able to register for competitions until you complete it!",
        url: profile_edit_path,
      }
    end

    notifications
  end
end
