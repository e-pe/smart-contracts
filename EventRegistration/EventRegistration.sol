pragma solidity ^0.4.4;

contract EventRegistration {
    struct Registrant {
        uint amount;
        uint numberOfTickets;
        string emailAddress;
        address ledgerAddress;
    }

    address public owner;
    uint public numberOfTicketsSold;
    uint public numberOfTicketsToSell;
    uint public ticketPrice;
    bool public registrationClosed;

    mapping(address => Registrant) public registrantsPaid;

    event RegistrantPaid(address _from, uint amount);
    event RegistrantRefund(address _to, uint _amount);
    event RegistrationClosed();

    modifier onlyOwner() {
        require(msg.sender == owner);

        _;
    }

    modifier soldOut(uint numberOfTicketsToBuy) {
        require(numberOfTicketsSold + numberOfTicketsToBuy <= numberOfTicketsToSell);

        _;
    }

    function EventRegistration(uint _numberOfTicketsToSell, uint _ticketPrice) public {
        owner = msg.sender;
        numberOfTicketsToSell = _numberOfTicketsToSell;
        ticketPrice = _ticketPrice;
        numberOfTicketsSold = 0;
        registrationClosed = false;
    }

    function buyTicket(string email, uint numberOfTickets) payable soldOut(numberOfTickets) public {
        uint amountToPay = numberOfTickets * ticketPrice;
        uint amountToRefund = msg.value - amountToPay;

        require(numberOfTickets > 0);
        require(msg.value >= amountToPay);
        require(registrationClosed == false);
        
        Registrant storage registrant = registrantsPaid[msg.sender];
        registrant.emailAddress = email;
        registrant.ledgerAddress = msg.sender;
        registrant.amount += amountToPay;
        registrant.numberOfTickets += numberOfTickets;

        numberOfTicketsSold = numberOfTicketsSold + numberOfTickets;
        
        if (amountToRefund > 0) {
            registrant.ledgerAddress.transfer(amountToRefund);
        }
        
        RegistrantPaid(registrant.ledgerAddress, amountToPay);
    }

    function refundTicket(address buyer) payable onlyOwner public {
        Registrant storage registrant = registrantsPaid[buyer];

        uint amountToRefund = registrant.amount;

        require(buyer != address(0));
        require(registrant.ledgerAddress == buyer);

        require(amountToRefund > 0);
        require(this.balance >= amountToRefund);
        require(registrationClosed == false);

        buyer.transfer(registrant.amount);

        numberOfTicketsSold -= registrant.numberOfTickets;

        registrant.amount = 0;
        registrant.numberOfTickets = 0;

        RegistrantRefund(buyer, amountToRefund);        
    }

    function closeRegistration() onlyOwner public {
        registrationClosed = true;

        RegistrationClosed();
    }

    function registrantAmountPaid(address buyer) constant public returns(uint) {
        Registrant storage registrant = registrantsPaid[buyer];

        return registrant.amount;
    }

    function withdrawFunds() payable public {
        owner.transfer(this.balance);
    }

    function destroy() onlyOwner public {
        selfdestruct(owner);
    }    
}