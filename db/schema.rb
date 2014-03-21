# This file is auto-generated from the current state of the database. Instead of editing this file,
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140303173209) do

  create_table "abuse_reports", :force => true do |t|
    t.integer  "reporter_id"
    t.integer  "abuse_complaint_id"
    t.text     "content"
    t.text     "reason"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "action_tracker", :force => true do |t|
    t.integer  "user_id"
    t.string   "user_type"
    t.integer  "target_id"
    t.string   "target_type"
    t.text     "params"
    t.string   "verb"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "comments_count", :default => 0
    t.boolean  "visible",        :default => true
  end

  add_index "action_tracker", ["target_id", "target_type"], :name => "index_action_tracker_on_dispatcher_id_and_dispatcher_type"
  add_index "action_tracker", ["user_id", "user_type"], :name => "index_action_tracker_on_user_id_and_user_type"
  add_index "action_tracker", ["verb"], :name => "index_action_tracker_on_verb"

  create_table "action_tracker_notifications", :force => true do |t|
    t.integer "action_tracker_id"
    t.integer "profile_id"
  end

  add_index "action_tracker_notifications", ["action_tracker_id"], :name => "index_action_tracker_notifications_on_action_tracker_id"
  add_index "action_tracker_notifications", ["profile_id", "action_tracker_id"], :name => "index_action_tracker_notifications_on_profile_id_and_action_tra", :unique => true
  add_index "action_tracker_notifications", ["profile_id"], :name => "index_action_tracker_notifications_on_profile_id"

  create_table "article_privacy_exceptions", :id => false, :force => true do |t|
    t.integer "article_id"
    t.integer "person_id"
  end

  create_table "article_versions", :force => true do |t|
    t.integer  "article_id"
    t.integer  "version"
    t.string   "name"
    t.string   "slug"
    t.text     "path",                 :default => ""
    t.integer  "parent_id"
    t.text     "body"
    t.text     "abstract"
    t.integer  "profile_id"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "last_changed_by_id"
    t.integer  "size"
    t.string   "content_type"
    t.string   "filename"
    t.integer  "height"
    t.integer  "width"
    t.string   "versioned_type"
    t.integer  "comments_count"
    t.boolean  "advertise",            :default => true
    t.boolean  "published",            :default => true
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "children_count",       :default => 0
    t.boolean  "accept_comments",      :default => true
    t.integer  "reference_article_id"
    t.text     "setting"
    t.boolean  "notify_comments",      :default => false
    t.integer  "hits",                 :default => 0
    t.datetime "published_at"
    t.string   "source"
    t.boolean  "highlighted",          :default => false
    t.string   "external_link"
    t.boolean  "thumbnails_processed", :default => false
    t.boolean  "is_image",             :default => false
    t.integer  "translation_of_id"
    t.string   "language"
    t.string   "source_name"
    t.integer  "license_id"
    t.integer  "image_id"
    t.integer  "position"
  end

  add_index "article_versions", ["article_id"], :name => "index_article_versions_on_article_id"
  add_index "article_versions", ["parent_id"], :name => "index_article_versions_on_parent_id"

  create_table "articles", :force => true do |t|
    t.string   "name"
    t.string   "slug"
    t.text     "path",                 :default => ""
    t.integer  "parent_id"
    t.text     "body"
    t.text     "abstract"
    t.integer  "profile_id"
    t.datetime "updated_at"
    t.datetime "created_at"
    t.integer  "last_changed_by_id"
    t.integer  "version"
    t.string   "type"
    t.integer  "size"
    t.string   "content_type"
    t.string   "filename"
    t.integer  "height"
    t.integer  "width"
    t.integer  "comments_count",       :default => 0
    t.boolean  "advertise",            :default => true
    t.boolean  "published",            :default => true
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "children_count",       :default => 0
    t.boolean  "accept_comments",      :default => true
    t.integer  "reference_article_id"
    t.text     "setting"
    t.boolean  "notify_comments",      :default => true
    t.integer  "hits",                 :default => 0
    t.datetime "published_at"
    t.string   "source"
    t.boolean  "highlighted",          :default => false
    t.string   "external_link"
    t.boolean  "thumbnails_processed", :default => false
    t.boolean  "is_image",             :default => false
    t.integer  "translation_of_id"
    t.string   "language"
    t.string   "source_name"
    t.integer  "license_id"
    t.integer  "image_id"
    t.integer  "position"
  end

  add_index "articles", ["parent_id"], :name => "index_articles_on_parent_id"
  add_index "articles", ["profile_id"], :name => "index_articles_on_profile_id"
  add_index "articles", ["slug"], :name => "index_articles_on_slug"
  add_index "articles", ["translation_of_id"], :name => "index_articles_on_translation_of_id"

  create_table "articles_categories", :id => false, :force => true do |t|
    t.integer "article_id"
    t.integer "category_id"
    t.boolean "virtual",     :default => false
  end

  add_index "articles_categories", ["article_id"], :name => "index_articles_categories_on_article_id"
  add_index "articles_categories", ["category_id"], :name => "index_articles_categories_on_category_id"

  create_table "blocks", :force => true do |t|
    t.string   "title"
    t.integer  "box_id"
    t.string   "type"
    t.text     "settings"
    t.integer  "position"
    t.boolean  "enabled",    :default => true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "fetched_at"
  end

  add_index "blocks", ["box_id"], :name => "index_blocks_on_box_id"
  add_index "blocks", ["enabled"], :name => "index_blocks_on_enabled"
  add_index "blocks", ["fetched_at"], :name => "index_blocks_on_fetched_at"
  add_index "blocks", ["type"], :name => "index_blocks_on_type"

  create_table "boxes", :force => true do |t|
    t.string  "owner_type"
    t.integer "owner_id"
    t.integer "position"
  end

  add_index "boxes", ["owner_type", "owner_id"], :name => "index_boxes_on_owner_type_and_owner_id"

  create_table "bsc_plugin_contracts", :force => true do |t|
    t.string   "client_name"
    t.integer  "client_type"
    t.integer  "business_type"
    t.string   "state"
    t.string   "city"
    t.integer  "status",              :default => 0
    t.integer  "number_of_producers", :default => 0
    t.datetime "supply_start"
    t.datetime "supply_end"
    t.text     "annotations"
    t.integer  "bsc_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bsc_plugin_contracts_enterprises", :id => false, :force => true do |t|
    t.integer "contract_id"
    t.integer "enterprise_id"
  end

  create_table "bsc_plugin_sales", :force => true do |t|
    t.integer  "product_id",  :null => false
    t.integer  "contract_id", :null => false
    t.integer  "quantity",    :null => false
    t.decimal  "price"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "categories", :force => true do |t|
    t.string  "name"
    t.string  "slug"
    t.text    "path",            :default => ""
    t.integer "display_color"
    t.integer "environment_id"
    t.integer "parent_id"
    t.string  "type"
    t.float   "lat"
    t.float   "lng"
    t.boolean "display_in_menu", :default => false
    t.integer "children_count",  :default => 0
    t.boolean "accept_products", :default => true
    t.integer "image_id"
    t.string  "acronym"
    t.string  "abbreviation"
    t.text    "ancestry"
  end

  add_index "categories", ["parent_id"], :name => "index_categories_on_parent_id"

  create_table "categories_profiles", :id => false, :force => true do |t|
    t.integer "profile_id"
    t.integer "category_id"
    t.boolean "virtual",     :default => false
  end

  add_index "categories_profiles", ["category_id"], :name => "index_categories_profiles_on_category_id"
  add_index "categories_profiles", ["profile_id"], :name => "index_categories_profiles_on_profile_id"

  create_table "certifiers", :force => true do |t|
    t.string   "name",           :null => false
    t.text     "description"
    t.string   "link"
    t.integer  "environment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", :force => true do |t|
    t.string   "title"
    t.text     "body"
    t.integer  "source_id"
    t.integer  "author_id"
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
    t.integer  "reply_of_id"
    t.string   "ip_address"
    t.boolean  "spam"
    t.string   "source_type"
    t.string   "user_agent"
    t.string   "referrer"
    t.integer  "group_id"
  end

  add_index "comments", ["source_id", "spam"], :name => "index_comments_on_source_id_and_spam"

  create_table "contact_lists", :force => true do |t|
    t.text     "list"
    t.string   "error_fetching"
    t.boolean  "fetched",        :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "custom_forms_plugin_answers", :force => true do |t|
    t.text    "value"
    t.integer "field_id"
    t.integer "submission_id"
  end

  create_table "custom_forms_plugin_fields", :force => true do |t|
    t.string  "name"
    t.string  "slug"
    t.string  "type"
    t.string  "default_value"
    t.string  "choices"
    t.float   "minimum"
    t.float   "maximum"
    t.integer "form_id"
    t.boolean "mandatory",     :default => false
    t.boolean "multiple"
    t.boolean "list"
    t.integer "position",      :default => 0
  end

  create_table "custom_forms_plugin_forms", :force => true do |t|
    t.string   "name"
    t.string   "slug"
    t.text     "description"
    t.integer  "profile_id"
    t.datetime "begining"
    t.datetime "ending"
    t.boolean  "report_submissions", :default => false
    t.boolean  "on_membership",      :default => false
    t.string   "access"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "custom_forms_plugin_submissions", :force => true do |t|
    t.string   "author_name"
    t.string   "author_email"
    t.integer  "profile_id"
    t.integer  "form_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0
    t.integer  "attempts",   :default => 0
    t.text     "handler"
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "delivery_plugin_methods", :force => true do |t|
    t.integer  "profile_id"
    t.string   "name"
    t.text     "description"
    t.string   "recipient"
    t.string   "address_line1"
    t.string   "address_line2"
    t.string   "postal_code"
    t.string   "state"
    t.string   "country"
    t.string   "delivery_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delivery_plugin_methods", ["profile_id"], :name => "index_distribution_plugin_delivery_methods_on_node_id"

  create_table "delivery_plugin_options", :force => true do |t|
    t.integer  "owner_id"
    t.integer  "delivery_method_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "owner_type"
  end

  add_index "delivery_plugin_options", ["delivery_method_id"], :name => "distribution_plugin_delivery_options_dmid"
  add_index "delivery_plugin_options", ["owner_id", "delivery_method_id"], :name => "distribution_plugin_delivery_options_sid_dmid"
  add_index "delivery_plugin_options", ["owner_id"], :name => "index_distribution_plugin_delivery_options_on_session_id"

  create_table "domains", :force => true do |t|
    t.string  "name"
    t.string  "owner_type"
    t.integer "owner_id"
    t.boolean "is_default",      :default => false
    t.string  "google_maps_key"
    t.boolean "ssl"
  end

  create_table "environments", :force => true do |t|
    t.string   "name"
    t.string   "contact_email"
    t.boolean  "is_default"
    t.text     "settings"
    t.text     "design_data"
    t.text     "custom_header"
    t.text     "custom_footer"
    t.string   "theme",                        :default => "default",           :null => false
    t.text     "terms_of_use_acceptance_text"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "send_email_plugin_allow_to"
    t.integer  "reports_lower_bound",          :default => 0,                   :null => false
    t.string   "languages"
    t.string   "default_language"
    t.string   "redirection_after_login",      :default => "keep_on_same_page"
    t.text     "signup_welcome_text"
    t.string   "noreply_email"
  end

  create_table "external_feeds", :force => true do |t|
    t.string   "feed_title"
    t.datetime "fetched_at"
    t.string   "address"
    t.integer  "blog_id",                         :null => false
    t.boolean  "enabled",       :default => true, :null => false
    t.boolean  "only_once",     :default => true, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "error_message"
    t.integer  "update_errors", :default => 0
  end

  add_index "external_feeds", ["blog_id"], :name => "index_external_feeds_on_blog_id"
  add_index "external_feeds", ["enabled"], :name => "index_external_feeds_on_enabled"
  add_index "external_feeds", ["fetched_at"], :name => "index_external_feeds_on_fetched_at"

  create_table "favorite_enteprises_people", :id => false, :force => true do |t|
    t.integer "person_id"
    t.integer "enterprise_id"
  end

  create_table "friendships", :force => true do |t|
    t.integer  "person_id"
    t.integer  "friend_id"
    t.datetime "created_at"
    t.string   "group"
  end

  add_index "friendships", ["friend_id"], :name => "index_friendships_on_friend_id"
  add_index "friendships", ["person_id", "friend_id"], :name => "index_friendships_on_person_id_and_friend_id"
  add_index "friendships", ["person_id"], :name => "index_friendships_on_person_id"

  create_table "images", :force => true do |t|
    t.integer "parent_id"
    t.string  "content_type"
    t.string  "filename"
    t.string  "thumbnail"
    t.integer "size"
    t.integer "width"
    t.integer "height"
    t.boolean "thumbnails_processed", :default => false
  end

  add_index "images", ["parent_id"], :name => "index_images_on_parent_id"

  create_table "inputs", :force => true do |t|
    t.integer  "product_id",                                    :null => false
    t.integer  "product_category_id",                           :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "position"
    t.decimal  "price_per_unit"
    t.decimal  "amount_used"
    t.boolean  "relevant_to_price",          :default => true
    t.boolean  "is_from_solidarity_economy", :default => false
    t.integer  "unit_id"
  end

  add_index "inputs", ["product_category_id"], :name => "index_inputs_on_product_category_id"
  add_index "inputs", ["product_id"], :name => "index_inputs_on_product_id"

  create_table "licenses", :force => true do |t|
    t.string  "name",           :null => false
    t.string  "slug",           :null => false
    t.string  "url"
    t.integer "environment_id", :null => false
  end

  create_table "mailing_sents", :force => true do |t|
    t.integer  "mailing_id"
    t.integer  "person_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mailings", :force => true do |t|
    t.string   "type"
    t.string   "subject"
    t.text     "body"
    t.integer  "source_id"
    t.string   "source_type"
    t.integer  "person_id"
    t.string   "locale"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mezuro_plugin_metrics", :force => true do |t|
    t.string   "name"
    t.float    "value"
    t.integer  "metricable_id"
    t.string   "metricable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "mezuro_plugin_projects", :force => true do |t|
    t.string   "name"
    t.string   "identifier"
    t.string   "personal_webpage"
    t.text     "description"
    t.string   "repository_url"
    t.string   "svn_error"
    t.boolean  "with_tab"
    t.integer  "profile_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "national_region_types", :force => true do |t|
    t.string "name"
  end

  create_table "national_regions", :force => true do |t|
    t.string   "name"
    t.string   "national_region_code"
    t.string   "parent_national_region_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "national_region_type_id"
  end

  add_index "national_regions", ["name"], :name => "name_index"
  add_index "national_regions", ["national_region_code"], :name => "code_index"

  create_table "oauth2_authorizations", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "oauth2_resource_owner_type"
    t.integer  "oauth2_resource_owner_id"
    t.integer  "client_id"
    t.string   "scope"
    t.string   "code",                       :limit => 40
    t.string   "access_token_hash",          :limit => 40
    t.string   "refresh_token_hash",         :limit => 40
    t.datetime "expires_at"
  end

  add_index "oauth2_authorizations", ["access_token_hash"], :name => "index_oauth2_authorizations_on_access_token_hash", :unique => true
  add_index "oauth2_authorizations", ["client_id", "code"], :name => "index_oauth2_authorizations_on_client_id_and_code", :unique => true
  add_index "oauth2_authorizations", ["client_id", "oauth2_resource_owner_type", "oauth2_resource_owner_id"], :name => "index_owner_client_pairs", :unique => true
  add_index "oauth2_authorizations", ["client_id", "refresh_token_hash"], :name => "index_oauth2_authorizations_on_client_id_and_refresh_token_hash", :unique => true

  create_table "oauth2_clients", :force => true do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "oauth2_client_owner_type"
    t.integer  "oauth2_client_owner_id"
    t.string   "name"
    t.string   "client_id"
    t.string   "client_secret"
    t.string   "redirect_uri"
    t.integer  "image_id"
    t.string   "site"
  end

  add_index "oauth2_clients", ["client_id"], :name => "index_oauth2_clients_on_client_id", :unique => true
  add_index "oauth2_clients", ["name"], :name => "index_oauth2_clients_on_name", :unique => true

  create_table "oauth_plugin_providers", :force => true do |t|
    t.integer  "environment_id"
    t.string   "type"
    t.string   "strategy"
    t.string   "identifier"
    t.string   "name"
    t.string   "site"
    t.integer  "image_id"
    t.string   "key"
    t.string   "secret"
    t.text     "scope"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_plugin_providers", ["environment_id", "identifier"], :name => "index_oauth_plugin_providers_on_environment_id_and_identifier"
  add_index "oauth_plugin_providers", ["environment_id"], :name => "index_oauth_plugin_providers_on_environment_id"
  add_index "oauth_plugin_providers", ["identifier"], :name => "index_oauth_plugin_providers_on_identifier"
  add_index "oauth_plugin_providers", ["strategy"], :name => "index_oauth_plugin_providers_on_strategy"
  add_index "oauth_plugin_providers", ["type"], :name => "index_oauth_plugin_providers_on_type"

  create_table "orders_cycle_plugin_cycle_orders", :force => true do |t|
    t.integer  "cycle_id"
    t.integer  "order_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "orders_cycle_plugin_cycle_orders", ["cycle_id", "order_id"], :name => "index_orders_cycle_plugin_cycle_orders_on_cycle_id_and_order_id"
  add_index "orders_cycle_plugin_cycle_orders", ["cycle_id"], :name => "index_orders_cycle_plugin_cycle_orders_on_cycle_id"
  add_index "orders_cycle_plugin_cycle_orders", ["order_id"], :name => "index_orders_cycle_plugin_cycle_orders_on_order_id"

  create_table "orders_cycle_plugin_cycle_products", :force => true do |t|
    t.integer "cycle_id"
    t.integer "product_id"
  end

  add_index "orders_cycle_plugin_cycle_products", ["cycle_id", "product_id"], :name => "orders_cycle_plugin_index_PhBVTRFB"
  add_index "orders_cycle_plugin_cycle_products", ["cycle_id"], :name => "orders_cycle_plugin_index_dqaEe7Hf"
  add_index "orders_cycle_plugin_cycle_products", ["product_id"], :name => "orders_cycle_plugin_index_f5DmQ6w5Y"

  create_table "orders_cycle_plugin_cycles", :force => true do |t|
    t.integer  "profile_id"
    t.string   "name"
    t.text     "description"
    t.datetime "start"
    t.datetime "finish"
    t.datetime "delivery_start"
    t.datetime "delivery_finish"
    t.decimal  "margin_percentage"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "status"
    t.integer  "code"
    t.text     "opening_message"
  end

  add_index "orders_cycle_plugin_cycles", ["code"], :name => "index_orders_cycle_plugin_cycles_on_code"
  add_index "orders_cycle_plugin_cycles", ["profile_id"], :name => "index_distribution_plugin_sessions_on_node_id"
  add_index "orders_cycle_plugin_cycles", ["status"], :name => "index_distribution_plugin_sessions_on_status"

  create_table "orders_plugin_items", :force => true do |t|
    t.integer  "product_id"
    t.integer  "order_id"
    t.decimal  "quantity_asked",    :default => 0.0
    t.decimal  "quantity_accepted", :default => 0.0
    t.decimal  "quantity_shipped",  :default => 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "price_asked",       :default => 0.0
    t.decimal  "price_accepted",    :default => 0.0
    t.decimal  "price_shipped",     :default => 0.0
    t.text     "data",              :default => "--- {}\n\n"
    t.string   "name"
    t.decimal  "price"
  end

  add_index "orders_plugin_items", ["order_id"], :name => "index_distribution_plugin_ordered_products_on_order_id"
  add_index "orders_plugin_items", ["product_id"], :name => "distribution_plugin_ordered_products_spid"

  create_table "orders_plugin_orders", :force => true do |t|
    t.integer  "profile_id"
    t.integer  "consumer_id"
    t.integer  "supplier_delivery_id"
    t.integer  "consumer_delivery_id"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "code"
    t.text     "profile_data",           :default => "--- {}\n\n"
    t.text     "consumer_data",          :default => "--- {}\n\n"
    t.text     "supplier_delivery_data", :default => "--- {}\n\n"
    t.text     "consumer_delivery_data", :default => "--- {}\n\n"
    t.text     "payment_data",           :default => "--- {}\n\n"
    t.text     "data",                   :default => "--- {}\n\n"
  end

  add_index "orders_plugin_orders", ["consumer_delivery_id"], :name => "index_distribution_plugin_orders_on_consumer_delivery_id"
  add_index "orders_plugin_orders", ["consumer_id"], :name => "index_distribution_plugin_orders_on_consumer_id"
  add_index "orders_plugin_orders", ["profile_id"], :name => "index_distribution_plugin_orders_on_session_id"
  add_index "orders_plugin_orders", ["status"], :name => "index_distribution_plugin_orders_on_status"
  add_index "orders_plugin_orders", ["supplier_delivery_id"], :name => "index_distribution_plugin_orders_on_supplier_delivery_id"

  create_table "price_details", :force => true do |t|
    t.decimal  "price",              :default => 0.0
    t.integer  "product_id"
    t.integer  "production_cost_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "product_qualifiers", :force => true do |t|
    t.integer  "product_id"
    t.integer  "qualifier_id"
    t.integer  "certifier_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "product_qualifiers", ["certifier_id"], :name => "index_product_qualifiers_on_certifier_id"
  add_index "product_qualifiers", ["product_id"], :name => "index_product_qualifiers_on_product_id"
  add_index "product_qualifiers", ["qualifier_id"], :name => "index_product_qualifiers_on_qualifier_id"

  create_table "production_costs", :force => true do |t|
    t.string   "name"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", :force => true do |t|
    t.integer  "profile_id"
    t.integer  "product_category_id"
    t.string   "name"
    t.decimal  "price"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.decimal  "discount"
    t.boolean  "available",           :default => true
    t.boolean  "highlighted",         :default => false
    t.integer  "unit_id"
    t.integer  "image_id"
    t.string   "type"
    t.text     "data"
    t.boolean  "archived",            :default => false
  end

  add_index "products", ["product_category_id"], :name => "index_products_on_product_category_id"
  add_index "products", ["profile_id"], :name => "index_products_on_enterprise_id"

  create_table "profiles", :force => true do |t|
    t.string   "name"
    t.string   "type"
    t.string   "identifier"
    t.integer  "environment_id"
    t.boolean  "active",                                :default => true
    t.string   "address"
    t.string   "contact_phone"
    t.integer  "home_page_id"
    t.integer  "user_id"
    t.integer  "region_id"
    t.text     "data"
    t.datetime "created_at"
    t.float    "lat"
    t.float    "lng"
    t.integer  "geocode_precision"
    t.boolean  "enabled",                               :default => true
    t.string   "nickname",                :limit => 16
    t.text     "custom_header"
    t.text     "custom_footer"
    t.string   "theme"
    t.boolean  "public_profile",                        :default => true
    t.date     "birth_date"
    t.integer  "preferred_domain_id"
    t.datetime "updated_at"
    t.boolean  "visible",                               :default => true
    t.integer  "image_id"
    t.integer  "bsc_id"
    t.string   "company_name"
    t.boolean  "validated",                             :default => true
    t.string   "cnpj"
    t.string   "national_region_code"
    t.boolean  "is_template",                           :default => false
    t.integer  "template_id"
    t.string   "redirection_after_login"
  end

  add_index "profiles", ["environment_id"], :name => "index_profiles_on_environment_id"
  add_index "profiles", ["identifier"], :name => "index_profiles_on_identifier"
  add_index "profiles", ["region_id"], :name => "index_profiles_on_region_id"

  create_table "qualifier_certifiers", :force => true do |t|
    t.integer "qualifier_id"
    t.integer "certifier_id"
  end

  create_table "qualifiers", :force => true do |t|
    t.string   "name",           :null => false
    t.integer  "environment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "refused_join_community", :id => false, :force => true do |t|
    t.integer "person_id"
    t.integer "community_id"
  end

  create_table "region_validators", :id => false, :force => true do |t|
    t.integer "region_id"
    t.integer "organization_id"
  end

  create_table "reported_images", :force => true do |t|
    t.integer "size"
    t.string  "content_type"
    t.string  "filename"
    t.integer "height"
    t.integer "width"
    t.integer "abuse_report_id"
  end

  create_table "role_assignments", :force => true do |t|
    t.integer "accessor_id",   :null => false
    t.string  "accessor_type"
    t.integer "resource_id"
    t.string  "resource_type"
    t.integer "role_id",       :null => false
    t.boolean "is_global"
  end

  create_table "roles", :force => true do |t|
    t.string  "name"
    t.text    "permissions"
    t.string  "key"
    t.boolean "system",         :default => false
    t.integer "environment_id"
  end

  create_table "scraps", :force => true do |t|
    t.text     "content"
    t.integer  "sender_id"
    t.integer  "receiver_id"
    t.integer  "scrap_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "suppliers_plugin_source_products", :force => true do |t|
    t.integer  "from_product_id"
    t.integer  "to_product_id"
    t.decimal  "quantity",        :default => 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "supplier_id"
  end

  add_index "suppliers_plugin_source_products", ["from_product_id", "to_product_id"], :name => "suppliers_plugin_index_dtBULzU3"
  add_index "suppliers_plugin_source_products", ["from_product_id"], :name => "index_distribution_plugin_source_products_on_from_product_id"
  add_index "suppliers_plugin_source_products", ["supplier_id", "from_product_id", "to_product_id"], :name => "suppliers_plugin_index_VBNqyeCP"
  add_index "suppliers_plugin_source_products", ["supplier_id", "from_product_id"], :name => "suppliers_plugin_index_naHsVLS6cH"
  add_index "suppliers_plugin_source_products", ["supplier_id"], :name => "suppliers_plugin_index_Lm5QPpV8"
  add_index "suppliers_plugin_source_products", ["to_product_id"], :name => "index_distribution_plugin_source_products_on_to_product_id"

  create_table "suppliers_plugin_suppliers", :force => true do |t|
    t.integer  "consumer_id"
    t.string   "name"
    t.string   "name_abbreviation"
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "profile_id"
    t.boolean  "active",            :default => true
  end

  add_index "suppliers_plugin_suppliers", ["consumer_id"], :name => "index_distribution_plugin_suppliers_on_consumer_id"
  add_index "suppliers_plugin_suppliers", ["profile_id", "consumer_id"], :name => "index_suppliers_plugin_suppliers_on_profile_id_and_consumer_id"
  add_index "suppliers_plugin_suppliers", ["profile_id"], :name => "index_suppliers_plugin_suppliers_on_profile_id"

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type"], :name => "index_taggings_on_taggable_id_and_taggable_type"

  create_table "tags", :force => true do |t|
    t.string  "name"
    t.integer "parent_id"
    t.boolean "pending",   :default => false
  end

  add_index "tags", ["parent_id"], :name => "index_tags_on_parent_id"

  create_table "tasks", :force => true do |t|
    t.text     "data"
    t.integer  "status"
    t.date     "end_date"
    t.integer  "requestor_id"
    t.integer  "target_id"
    t.string   "code",         :limit => 40
    t.string   "type"
    t.datetime "created_at"
    t.string   "target_type"
    t.integer  "image_id"
    t.integer  "bsc_id"
    t.boolean  "spam",                       :default => false
  end

  add_index "tasks", ["spam"], :name => "index_tasks_on_spam"

  create_table "terms_forum_people", :id => false, :force => true do |t|
    t.integer "forum_id"
    t.integer "person_id"
  end

  add_index "terms_forum_people", ["forum_id", "person_id"], :name => "index_terms_forum_people_on_forum_id_and_person_id"

  create_table "thumbnails", :force => true do |t|
    t.integer "size"
    t.string  "content_type"
    t.string  "filename"
    t.integer "height"
    t.integer "width"
    t.integer "parent_id"
    t.string  "thumbnail"
  end

  add_index "thumbnails", ["parent_id"], :name => "index_thumbnails_on_parent_id"

  create_table "units", :force => true do |t|
    t.string  "singular",       :null => false
    t.string  "plural",         :null => false
    t.integer "position"
    t.integer "environment_id", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.text     "terms_of_use"
    t.string   "terms_accepted",            :limit => 1
    t.integer  "environment_id"
    t.string   "password_type"
    t.boolean  "enable_email",                            :default => false
    t.string   "last_chat_status",                        :default => ""
    t.string   "chat_status",                             :default => ""
    t.datetime "chat_status_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
  end

  create_table "validation_infos", :force => true do |t|
    t.text    "validation_methodology"
    t.text    "restrictions"
    t.integer "organization_id"
  end

end
