pragma solidity ^0.4.4;

contract ProductSales {
    struct Product {
        uint id;
        string name;
        uint inventory;
        uint price;
    }
    
    struct Buyer {
        string name;
        string email;
        string mailingAddress;
        uint totalOrders;
        bool isActive;
    }
    
    struct Order {
        uint orderId;
        uint productId;
        uint quantity;
        address buyerAddress;
    }
    
    address public owner;
    
    mapping(address => Buyer) public buyers;
    mapping(uint => Product) public products;
    mapping(uint => Order) public orders;
    
    uint public numProducts;
    uint public numBuyers;
    uint public numOrders;
    
    event NewProductEvent(uint id, string name, uint inventory, uint price);
    event NewBuyerEvent(string name, string email, string mailingAddress);
    event NewOrderEvent(uint orderId, uint id, uint quantity, address from);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        
        _;
    }
    
    function ProductSales() public {
        owner = msg.sender;
        numBuyers = 0;
        numOrders = 0;
        numProducts = 0;
    }
    
    function addProduct(
        uint _id, 
        string _name, 
        uint _inventory, 
        uint _price) onlyOwner public {
        
        Product storage product = products[_id];
        product.id = _id;
        product.name = _name;
        product.inventory = _inventory;
        product.price = _price;
            
        numProducts++;
        
        NewProductEvent(
            product.id, 
            product.name, 
            product.inventory, 
            product.price);
    }
    
    function updateProduct(
        uint _id, 
        string _name,  
        uint _inventory, 
        uint _price) onlyOwner public {
            
        Product storage product = products[_id];
        product.name = _name;
        product.inventory = _inventory;
        product.price = _price;
    
    }
    
    function registerBuyer(
        string _name, 
        string _email, 
        string _mailingAddress) public {
            
        Buyer storage buyer = buyers[msg.sender];
        buyer.name = _name;
        buyer.email = _email;
        buyer.mailingAddress = _mailingAddress;
        buyer.totalOrders = 0;
        buyer.isActive = true;
        
        numBuyers++;
        
        NewBuyerEvent(buyer.name, buyer.email, buyer.mailingAddress);
    }
    
    function buyProduct(uint _productId, uint _quantity) payable public {
        Buyer storage buyer = buyers[msg.sender];
        Product storage product = products[_productId];
        
        uint amount = product.price * _quantity;
        
        require(product.inventory >= _quantity);
        require(buyer.isActive == true);
        require(msg.value >= amount);
        
        
        Order storage order = orders[numOrders];
        order.orderId = uint(msg.sender) + block.timestamp;
        order.productId = _productId;
        order.quantity = _quantity;
        order.buyerAddress = msg.sender;
        
        buyer.totalOrders += 1;
        product.inventory -= 1;
            
        numOrders++;
        
        if (msg.value > amount) {
            uint refundAmount = msg.value - amount;
            
            order.buyerAddress.transfer(refundAmount);
        }
        
        NewOrderEvent(order.orderId, _productId, _quantity, order.buyerAddress);
    }
    
    function withdrawFunds() onlyOwner public {
        owner.transfer(this.balance);
    }
    
    function destroy() onlyOwner public {
        selfdestruct(owner);
    }
}