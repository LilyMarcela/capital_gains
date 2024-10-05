# **Transaction Processing System**

This project is a simples transaction processing system built using Ruby. The system can handle multiple transaction types, such as **buy** and **sell**, and is designed to be easily extensible for future transaction types (e.g., dividends, stock splits). The system calculates taxes based on the profits of each sell transaction and maintains an internal portfolio with cumulative losses.

## **Technical and Architectural Decisions**

### **1. Object-Oriented Design**

The project is designed using object-oriented principles to allow for future extensibility. Each transaction type (e.g., `BuyTransaction`, `SellTransaction`) is a class that inherits from a base `Transaction` class. This separation allows each transaction type to encapsulate its specific logic while sharing common functionality.

### **2. Factory Pattern**

The `TransactionFactory` class is used to instantiate different types of transactions based on the operation type (e.g., buy or sell). This makes it easy to add new transaction types in the future without modifying existing logic. You only need to add a new transaction class and update the factory.

### **3. Immutability and Referential Transparency**

The portfolio object is designed to be immutable. Each time a transaction is applied, a new portfolio object is created and returned. This approach ensures that the state of the portfolio remains consistent and makes the code more predictable.

### **4. Minimal Use of External Libraries**

The solution uses core Ruby libraries like `json` for parsing input and `byebug` for debugging. No external frameworks were used to keep the solution lightweight and easily runnable in Unix or Mac environments.

## **Reasoning About the Frameworks Used**

- **Ruby Standard Library (`json`)**: Used for parsing the input transactions from JSON format. Since Ruby provides a built-in JSON library, there's no need for external libraries.
- **Byebug**: Used for debugging purposes, particularly useful during development for step-by-step execution.

## **Instructions to Compile and Run the Project**

1. **Prerequisites**:  
   Ensure you have Ruby installed on your system. You can check by running:

   ```bash
   ruby -v
   ```

### If Ruby is not installed

Follow the instructions on the official Ruby website to install it.

### Extract the Project from the .zip

Once you have downloaded the `.zip` file, extract it to your preferred directory.

```bash
unzip transaction_processing_system.zip
cd transaction_processing_system`
```

### Running the Project with Standard Input (CLI)

To run the project with transactions passed via standard input, use the following command:

```bash
echo '[{"operation": "buy", "unit-cost": 10.0, "quantity": 100}, {"operation": "sell", "unit-cost": 15.0, "quantity": 50}]' | ruby transaction_processor.rb
```

Running the Project with a JSON File
If you have a file with transaction data, you can pass the file as an argument to the Ruby script:

ruby transaction_processor.rb path/to/transactions.json

### Instructions to Run the Tests

Install RSpec for Testing
If you haven't already installed RSpec, you can install it by running:

```bash
gem install rspec
```

### Running Tests

You can run the tests using RSpec by navigating to the project directory and running the following command:

```bash
rspec
```

This will run all the unit and integration tests

### Additional Notes

### Extensibility

The system is designed to allow easy addition of new transaction types. If you want to add a new transaction (like dividends or stock splits), simply create a new class that inherits from Transaction and implement the apply_to method. Then, add the new class to the TransactionFactory.

### Debugging

byebug is included for debugging purposes.

### Running Environment

The project has been tested and works on Unix and Mac OS environments. It should work on any system with a valid Ruby installation.
