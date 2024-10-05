require_relative '../capital_gains'
require 'json'
require 'stringio'
require 'byebug'

RSpec.describe 'Capital Tax Calculator' do
  describe 'Transaction Subclasses' do
    let(:buy_transaction) { BuyTransaction.new({ "unit-cost" => 10.0, "quantity" => 100 }) }
    let(:sell_transaction) { SellTransaction.new({ "unit-cost" => 15.0, "quantity" => 50 }) }

    it 'correctly processes a buy transaction' do
      portfolio = Portfolio.new
      _, new_portfolio = buy_transaction.apply_to(portfolio)
      expect(new_portfolio.current_shares).to eq(100)
      expect(new_portfolio.average_buy_price).to eq(10.0)
    end

    it 'correctly processes a sell transaction' do
      portfolio = Portfolio.new(10.0, 100)
      tax, new_portfolio = sell_transaction.apply_to(portfolio)
      expect(new_portfolio.current_shares).to eq(50)
      expect(tax).to eq(0.0) # No tax for the first 50 shares
    end
  end

  describe Portfolio do
    let(:portfolio) { Portfolio.new }

    it 'processes a buy transaction correctly' do
      buy_transaction = BuyTransaction.new({ "unit-cost" => 10.0, "quantity" => 100 })
      _, new_portfolio = buy_transaction.apply_to(portfolio)
      expect(new_portfolio.current_shares).to eq(100)
      expect(new_portfolio.average_buy_price).to eq(10.0)
    end

    it 'processes a sell transaction with profit correctly' do
      portfolio = Portfolio.new(10.0, 1000)
      sell_transaction = SellTransaction.new({ "unit-cost" => 30.0, "quantity" => 500 })
      tax, new_portfolio = sell_transaction.apply_to(portfolio)
      expect(tax).to eq(0.0)
      expect(new_portfolio.current_shares).to eq(500)
    end

    it 'processes a sell transaction with loss correctly' do
      portfolio = Portfolio.new(10.0, 100)
      sell_transaction = SellTransaction.new({ "unit-cost" => 5.0, "quantity" => 50 })
      tax, new_portfolio = sell_transaction.apply_to(portfolio)
      expect(tax).to eq(0.0) # No tax on a loss
      expect(new_portfolio.cumulative_losses).to eq(250.0)
    end

    it 'handles cumulative losses correctly' do
      portfolio = Portfolio.new(10.0, 100)
      sell_transaction1 = SellTransaction.new({ "unit-cost" => 5.0, "quantity" => 50 })
      sell_transaction2 = SellTransaction.new({ "unit-cost" => 15.0, "quantity" => 50 })
      _, portfolio_after_loss = sell_transaction1.apply_to(portfolio)
      tax, new_portfolio = sell_transaction2.apply_to(portfolio_after_loss)
      expect(tax).to eq(0.0)
      expect(new_portfolio.cumulative_losses).to eq(0.0)
    end
  end

  describe 'process_transactions' do
    it 'processes a series of transactions correctly' do
      transactions = [
        BuyTransaction.new({ "unit-cost" => 10.0, "quantity" => 1000 }),
        SellTransaction.new({ "unit-cost" => 30.0, "quantity" => 800 }),
        SellTransaction.new({ "unit-cost" => 40.0, "quantity" => 200 })
      ]
      initial_portfolio = Portfolio.new
      processor = TransactionProcessor.new(transactions)
      results = processor.process(initial_portfolio)
      expect(results).to eq([
        { "tax" => "0.00" },    # No tax for the buy operation
        { "tax" => "3200.00" }, # Tax for the first sell operation
        { "tax" => "0.00" }     # No tax for the second sell operation because total amount < $20,000
      ])
    end
  end

  describe 'Integration Tests' do
    def capture_stdout
      old_stdout = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = old_stdout
    end

    it 'processes a single transaction correctly' do
      input = '[{"operation": "buy", "unit-cost": 10.00, "quantity": 100}]'
      expected_output = '[{"tax":"0.00"}]'

      transactions = parse_transactions(input)
      portfolio = Portfolio.new
      processor = TransactionProcessor.new(transactions)
      result = processor.process(portfolio)

      output = result.to_json

      expect(output.strip).to eq(expected_output)
    end


    it 'processes multiple transactions correctly' do
      input = [
        { "operation" => "buy", "unit-cost" => 10.00, "quantity" => 100 },
        { "operation" => "sell", "unit-cost" => 15.00, "quantity" => 50 },
        { "operation" => "sell", "unit-cost" => 15.00, "quantity" => 50 }
      ]
      expected_output = '[{"tax":"0.00"},{"tax":"0.00"},{"tax":"0.00"}]'

      transactions = parse_transactions(input.to_json)
      portfolio = Portfolio.new
      processor = TransactionProcessor.new(transactions)
      result = processor.process(portfolio)

      output = result.to_json
      expect(output.strip).to eq(expected_output)
    end

    it 'processes multiple transactions with cumulative losses and profits correctly - case 7' do
      input = [
        { "operation" => "buy", "unit-cost" => 10.00, "quantity" => 10000 },
        { "operation" => "sell", "unit-cost" => 2.00, "quantity" => 5000 },
        { "operation" => "sell", "unit-cost" => 20.00, "quantity" => 2000 },
        { "operation" => "sell", "unit-cost" => 20.00, "quantity" => 2000 },
        { "operation" => "sell", "unit-cost" => 25.00, "quantity" => 1000 },
        { "operation" => "buy", "unit-cost" => 20.00, "quantity" => 10000 },
        { "operation" => "sell", "unit-cost" => 15.00, "quantity" => 5000 },
        { "operation" => "sell", "unit-cost" => 30.00, "quantity" => 4350 },
        { "operation" => "sell", "unit-cost" => 30.00, "quantity" => 650 }
      ]

      expected_output = '[{"tax":"0.00"},{"tax":"0.00"},{"tax":"0.00"},{"tax":"0.00"},{"tax":"3000.00"},{"tax":"0.00"},{"tax":"0.00"},{"tax":"3700.00"},{"tax":"0.00"}]'

      transactions = parse_transactions(input.to_json)
      portfolio = Portfolio.new
      processor = TransactionProcessor.new(transactions)
      result = processor.process(portfolio)

      output = result.to_json
      expect(output.strip).to eq(expected_output)
    end



    it 'handles cumulative losses correctly' do
      input = [
        { "operation" => "buy", "unit-cost" => 10.00, "quantity" => 100 },
        { "operation" => "sell", "unit-cost" => 5.00, "quantity" => 50 },
        { "operation" => "sell", "unit-cost" => 20.00, "quantity" => 50 }
      ]
      expected_output = '[{"tax":"0.00"},{"tax":"0.00"},{"tax":"0.00"}]'

      transactions = parse_transactions(input.to_json)
      portfolio = Portfolio.new
      processor = TransactionProcessor.new(transactions)
      result = processor.process(portfolio)

      output = result.to_json
      expect(output.strip).to eq(expected_output)
    end


    it 'handles multiple buy and sell operations correctly' do
      input = [
        { "operation" => "buy", "unit-cost" => 10.00, "quantity" => 10000 },
        { "operation" => "sell", "unit-cost" => 20.00, "quantity" => 5000 },
        { "operation" => "sell", "unit-cost" => 5.00, "quantity" => 5000 }
      ]
      expected_output = '[{"tax":"0.00"},{"tax":"10000.00"},{"tax":"0.00"}]'

      transactions = parse_transactions(input.to_json)
      portfolio = Portfolio.new
      processor = TransactionProcessor.new(transactions)
      result = processor.process(portfolio)

      output = result.to_json
      expect(output.strip).to eq(expected_output)
    end

  end
end
