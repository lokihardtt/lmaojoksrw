class MultisigTransaction < ActiveRecord::Base
  
  def self.send_btc_to_vendor_mutltisig(order_id)
    multi_sig = self.where(order_id: order_id).first
    get_raw_transaction = `bitcoin-cli getrawtransaction #{multi_sig.tx_id}`.gsub(/\n/, '')
    decode_raw_transaction = `bitcoin-cli decoderawtransaction #{get_raw_transaction}`.gsub(/\n/, "").gsub(/:/, "=>")
    decode_raw_transaction = eval(decode_raw_transaction)
    vout = decode_raw_transaction["vout"].first["n"]
    script_pub_key = decode_raw_transaction["vout"].first["scriptPubKey"]["hex"]
    create_raw_transaction = `bitcoin-cli createrawtransaction '[{"txid":"#{multi_sig.tx_id.gsub(/\n/, '')}","vout":#{vout},"scriptPubKey":"#{script_pub_key}","redeemScript":"#{multi_sig.redeem_script}" }]' '{"#{multi_sig.vendor_address}":#{multi_sig.total}}'`.gsub(/\n/, '')
    if create_raw_transaction.present?
        sign_raw_transaction_with_shop_pub_key = `bitcoin-cli signrawtransaction '#{create_raw_transaction}' '[{"txid":"#{multi_sig.tx_id.gsub(/\n/, '')}","vout":#{vout},"scriptPubKey":"#{script_pub_key}","redeemScript":"#{multi_sig.redeem_script}" }]' '["#{multi_sig.shop_pub_key}"]'`.gsub(/\n/, "").gsub(/:/, "=>")
        sign_raw_transaction_with_shop_pub_key = eval(sign_raw_transaction_with_shop_pub_key)
        hex = sign_raw_transaction_with_shop_pub_key["hex"]
        sign_raw_transaction_with_buyer_pub_key = `bitcoin-cli signrawtransaction '#{hex}' '[{"txid":"#{multi_sig.tx_id.gsub(/\n/, '')}","vout":#{vout},"scriptPubKey":"#{script_pub_key}","redeemScript":"#{multi_sig.redeem_script}"}]' '["#{multi_sig.buyer_pub_key}"]'`.gsub(/\n/, "").gsub(/:/, "=>")
        sign_raw_transaction_with_buyer_pub_key = eval(sign_raw_transaction_with_buyer_pub_key)
        new_hex = sign_raw_transaction_with_buyer_pub_key["hex"]
        send_raw_transaction = `bitcoin-cli sendrawtransaction #{new_hex}`.gsub(/\n/, '')
    else
      create_raw_transaction
    end
  end

end
