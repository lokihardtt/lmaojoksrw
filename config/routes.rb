Rails.application.routes.draw do

  apipie
  resources :addresses

  resources :messages

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  scope "(:locale)" do
    resources :private_messages
    get "support_contact" => "private_messages#support_contact"
    post "message_support_contact" => "private_messages#message_support_contact"
    get "reply" => "private_messages#reply"
    get "trash" => "private_messages#trash"
    get "untrash" => "private_messages#untrash"
    get "show_pgp" => "private_messages#show_pgp"
    get "show_sender_detail" => "private_messages#show_sender_detail"
    get "read_conversation" => "private_messages#read_conversation"
    get "unread_conversation" => "private_messages#unread_conversation"
    get "trash_private_message" => "private_messages#trash_private_message"
    get "untrash_private_message" => "private_messages#untrash_private_message"
    get "read_private_message" => "private_messages#read_private_message"
    get "unread_private_message" => "private_messages#unread_private_message"
    
    resources :orders do 
      post "confirm_order" => "orders#confirm_order"
      get "shipped_order" => "orders#shipped_order"
      post "request_buyer_attention_order" => "orders#request_buyer_attention_order"
      post "partially_shipped_order" => "orders#partially_shipped_order"
      get "cancel_order" => "orders#cancel"
    end
    
    get "auth_payment" => "orders#auth_payment" 
    post "finalize_order" => "orders#finalize_order"
    post "sent_order" => "orders#sent_order"
    get "orders/details/:id" => "orders#order_detail", as: :order_detail
    get "order_list" => "orders#order_list", as: :orders_list
    get "waiting_list" => "orders#waiting_list", as: :waiting_list
    get "approve_and_sent_orders" => "orders#approve_and_sent_orders", as: :approve_and_sent_orders
    post "pay" => "orders#pay", as: :pay
    get "pay_order_in_order" => "orders#pay_order_in_order", as: :pay_order_in_order
    get "pay_multisig" => "orders#pay_multisig"
    get "account_btc" => "orders#account", as: :bitcoin_account
    post "withdraw_funds" => "orders#withdraw_funds"
    post "transfer_fund" => "orders#transfer_fund"
    get "member" => "orders#member"
    get "create_new_bitcoin_address" => "orders#create_new_bitcoin_address", as: :create_new_bitcoin_address
    get "form_refund" => "orders#form_refund"
    post "refund_order" => "orders#refund_order", as: :refund_order
    get "validate_wallet" => "orders#validate_wallet", as: :validate_wallet
    get "pay_if_fund_not_enough" => "orders#pay_if_fund_not_enough", as: :pay_if_fund_not_enough

    resources :items, except: [:destroy]
    get "destroy_item" => "items#destroy"
    get "destroy_shipping_option" => "items#destroy_shipping_option"
    get "confirm_delete" => "items#confirm_delete", as: :confirm_delete
    get "copy_item" => "items#copy_item", as: :copy_item
    get "change_status" => "items#change_status", as: :change_status
    get "shipping_option/new" => "items#shipping_option_new"
    post "shipping_options" => "items#create_shpping_option_new"
    get "shipping_option_list" => "items#shipping_option_list", as: :shipping_option_list
    get "shipping_option/:id/edit" => "items#shipping_option_edit", as: :shipping_option_edit
    patch "shipping_option/:id" => "items#update_shipping_options", as: :shipping_option
    get "vendor_item" => "items#vendor_item"

    resources :categories
    resource :shopping_cart
    get "delete_cart/:id" => "shopping_carts#delete_cart", as: :delete_cart
    post "shopping_carts/encrypt_shipping_information"
    post "shopping_carts/pay_page"
    get "pay_order" => "shopping_carts#pay_order", as: :pay_order
    get "create_multi_sig" => "shopping_carts#create_multi_sig"
    post "shopping_carts/generate_multi_sig"
    get "pay_qr" => "shopping_cart#pay_qr", as: :pay_qr

    devise_scope :user do
      get 'users/vendor_sign_up', to: 'users/registrations#vendor_sign_up', as: 'vendor_sign_up'
      get ":token/register", to: "users/registrations#new"
    end
    devise_for :users, :controllers => { :registrations => "users/registrations", :sessions => "users/sessions" }
    resources :conversations, only: [:index, :show, :new, :create] do
      collection do
        get :inbox
        get :sentbox
        get :trash_list
      end
      member do
        post :reply
        post :trash
        post :untrash
      end
    end
    get "uncategories_items" => "dashboard#uncategories_items", as: :uncategories_items
    get "item_search" => "dashboard#item_search", as: :item_search
    get "category/:id" => "dashboard#item_by_category", as: :item_by_category
    get "dashboard" => "dashboard#dashboard", as: :dashboard
    post "dashboard" => "dashboard#dashboard", as: :dashboard_post
    get "dashboard_vendor" => "dashboard#dashboard_vendor", as: :dashboard_vendor
    post "dashboard_vendor" => "dashboard#dashboard_vendor", as: :dashboard_vendor_post
    get "list_country" => "dashboard#list_country"
    get "show_item_by_country" => "dashboard#show_item_by_country"
    get "item-detail/:random_string" => "dashboard#item_detail", as: :item_detail
    get "account" => "dashboard#show_buyer", as: :buyer_account
    get "show_full_image/:random_string" => "dashboard#show_full_image", as: :show_full_image
    get "upload-pgp-key" => "pgp#upload_key"
    post "pgp/check_pgp_key"
    get "input_string" => "pgp#input_string"
    get "input_string_from_profile" => "pgp#input_string_from_profile" 
    get "input_string_first_time" => "pgp#input_string_first_time" 
    get "confirmation_change_password" => "pgp#confirmation_change_password"
    get "change_password" => "pgp#change_password"
    post "pgp/check_random_string"
    post "pgp/check_random_string_from_profile"
    post "pgp/check_random_string_first_time"
    post "pgp/confirm_new_password"
    get "history" => "history#index", as: :history
    get "home" => "home#index"
    get "invite_new_buyer" => "invites#invite_new_buyer"
    get "invites/cancel_invited"
    post "invites/sent_invitation"
    get "new_wallet" => "blockchain#new_wallet"
    post "blockchain/create_new_wallet"
    # get '*path' => redirect("/")

    root 'home#index'
  end

  namespace :api do
    namespace :v1 do
      devise_scope :user do
        post 'login' => 'sessions#create', as: 'login'
        delete 'logout' => 'sessions#destroy', as: 'logout'
      end
      get "dashboard" => "dashboard#dashboard"
      get "dashboard_vendor" => "dashboard#dashboard_vendor"
      get "category/:id" => "dashboard#item_by_category", as: :item_by_category
      get "account" => "dashboard#show_buyer", as: :buyer_account
      get "item-detail/:id" => "dashboard#item_detail"

      get "categories" => "categories#index"

      get "shipping_options" => "shipping_options#index"
      get "shipping_options/:id/edit" => "shipping_options#edit"
      post "shipping_options/:id" => "shipping_options#update"
      post "create_shipping_option" => "shipping_options#create"

      get "countries" => "countries#index"
      get "ship_from" => "countries#ship_from"
      get "ship_to" => "countries#ship_to"

      get "currencies" => "currency_config#index"

      post "create_user" => "users#create"
      get "users/:id/edit" => "users#edit"
      post "users/:id" => "users#update"

      get "messages" => "messages#index"
      get "list_recipient" => "messages#list_recipient"
      get "create_message" => "messages#create_message"
      post "sent_message" => "messages#sent_message"
      get "reply" => "messages#reply"
      get "support_contact" => "messages#support_contact"
      post "message_support_contact" => "messages#message_support_contact"

      get "items" => "items#index"
      get "copy_item" => "items#copy_item"
      get "change_status" => "items#change_status"
      get "destroy_item" => "items#destroy"
      get "items/:id/edit" => "items#edit"
      post "items/:id" => "items#update"
      post "create_item" => "items#create"

      get "order_list" => "orders#order_list"
      get "orders" => "orders#index"
      get "orders/:order_id/shipped_order" => "orders#shipped_order"
      post "sent_order" => "orders#sent_order"
      get "form_refund" => "orders#form_refund"
      post "refund_order" => "orders#refund_order"
      post "finalize_order" => "orders#finalize_order"
      get "account_btc" => "orders#account"
      get "create_new_bitcoin_address" => "orders#create_new_bitcoin_address"
      get "member" => "orders#member"
      post "withdraw_funds" => "orders#withdraw_funds"
      post "transfer_fund" => "orders#transfer_fund"
      get "pay_order_in_order" => "orders#pay_order_in_order"

      post "shopping_cart" => "shopping_carts#create"
      post "shopping_carts/update_order"
      get "shopping_cart" => "shopping_carts#show"
      post "shopping_carts/message_information"
      get "pay" => "shopping_carts#pay"
      post '/delete_cart/:id' => "shopping_carts#delete_cart"
    end  
  end
end