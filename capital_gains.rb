require 'json'
require 'byebug'

class TransactionFactory
  def self.create_transaction(data)
    case data["operation"]
    when "buy"
      BuyTransaction.new(data)
    when "sell"
      SellTransaction.new(data)
    else
      raise "Unknown operation type: #{data["operation"]}"
    end
  end
end

class Transaction
  attr_reader :unit_cost, :quantity

  def initialize(data)
    @unit_cost = data["unit-cost"]
    @quantity = data["quantity"]
  end

  def apply_to(portfolio)
    raise NotImplementedError
  end
end

# BuyTransaction handles buying of shares
class BuyTransaction < Transaction
  def apply_to(portfolio)
    # Calculate the total cost of the shares after buying
    total_cost = (portfolio.average_buy_price * portfolio.current_shares) + (unit_cost * quantity)
    
    new_shares = portfolio.current_shares + quantity
    new_average_price = total_cost / new_shares
    new_portfolio = Portfolio.new(new_average_price, new_shares, portfolio.cumulative_losses)
    
    [0.0, new_portfolio]  # No tax for buy transactions
  end
end

class SellTransaction < Transaction
  def apply_to(portfolio)
    total_sale_amount = unit_cost * quantity
    total_cost_basis = portfolio.average_buy_price * quantity
    
    profit_or_loss = total_sale_amount - total_cost_basis
    
    new_shares = portfolio.current_shares - quantity

    if profit_or_loss > 0
      remaining_profit = portfolio.deduct_cumulative_losses(profit_or_loss)
      tax = portfolio.calculate_tax(remaining_profit, total_sale_amount)
    else
      portfolio.handle_loss(profit_or_loss.abs)
      tax = 0.00 # No tax on losses
    end

    new_portfolio = Portfolio.new(portfolio.average_buy_price, new_shares, portfolio.cumulative_losses)

    [tax, new_portfolio]
  end
end

# Tracks the number of shares, average buy price, and cumulative losses
class Portfolio
  attr_reader :average_buy_price, :current_shares, :cumulative_losses

  def initialize(average_buy_price = 0.0, current_shares = 0, cumulative_losses = 0.0)
    @average_buy_price = average_buy_price
    @current_shares = current_shares
    @cumulative_losses = cumulative_losses
  end

  def deduct_cumulative_losses(profit)
    if @cumulative_losses > 0
      if @cumulative_losses >= profit
        @cumulative_losses -= profit
        0.0  
      else
        remaining_profit = profit - @cumulative_losses
        @cumulative_losses = 0.0  
        remaining_profit
      end
    else
      profit  
    end
  end

  # Add losses to cumulative losses
  def handle_loss(loss)
    @cumulative_losses += loss
  end

  def calculate_tax(profit, total_sale_amount)
    if total_sale_amount > 20000 && profit > 0
      (profit * 0.20).round(2)  # 20% tax on profit
    else
      0.00  # No tax if sale amount < $20,000 or no profit
    end
  end
end

class TransactionProcessor
  def initialize(transactions)
    @transactions = transactions
  end

  # Applies each transaction to the initial portfolio and calculates taxes
  def process(initial_portfolio)
    portfolio = initial_portfolio
    @transactions.each_with_object([]) do |transaction, taxes|
      tax, portfolio = transaction.apply_to(portfolio)
      formatted_tax = format('%.2f', tax)  # Format tax to two decimal places
      taxes << { "tax" => formatted_tax }
    end
  end
end

def parse_transactions(json)
  JSON.parse(json).map do |data|
    TransactionFactory.create_transaction(data)
  end
end

def process_transactions(transactions_json)
  transactions = parse_transactions(transactions_json)
  initial_portfolio = Portfolio.new
  processor = TransactionProcessor.new(transactions)
  processor.process(initial_portfolio)
end

if __FILE__ == $PROGRAM_NAME
  if ARGV.empty?
    ARGF.each_line do |line|
      tax_results = process_transactions(line)
      puts tax_results.to_json
    end
  else
    ARGV.each do |filename|
      if File.exist?(filename)
        file_content = File.read(filename)
        tax_results = process_transactions(file_content)
        puts tax_results.to_json
      else
        puts "File not found: #{filename}"
      end
    end
  end
end
