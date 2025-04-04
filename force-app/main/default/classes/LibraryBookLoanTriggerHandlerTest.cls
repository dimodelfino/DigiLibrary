@isTest
private class LibraryBookLoanTriggerHandlerTest {

    @isTest
    static void testHandleInsert_SingleLoan_SufficientCopies() {

        Library_Book__c book = new Library_Book__c(Title__c = 'Test Book', Author__c = 'Test Author', Available_Copies__c = 3);

        insert book;

        Contact borrower = new Contact(
			FirstName = 'Test',
			LastName = 'Borrower'
		);

        insert borrower;

        Library_Book_Loan__c newLoan = new Library_Book_Loan__c(Book__c = book.Id, Borrower__c = borrower.Id, Loan_Start_Date__c = Date.today(), Loan_End_Date__c = Date.today().addDays(7));

        Test.startTest();
        insert newLoan;
        Test.stopTest();

        Library_Book__c updatedBook = [SELECT Id, Available_Copies__c FROM Library_Book__c WHERE Id = :book.Id];
        System.assertEquals(2, updatedBook.Available_Copies__c, 'Available copies should decrease by 1 after a successful loan');
    }

    @isTest
    static void testHandleInsert_MultipleLoans_SufficientCopies() {

        Library_Book__c book = new Library_Book__c(Title__c = 'Test Book', Author__c = 'Some Writer', Available_Copies__c = 5);

        insert book;

        Contact borrower1 = new Contact(
			FirstName = 'Borrower',
			LastName = 'One'
		);

        Contact borrower2 = new Contact(
			FirstName = 'Borrower',
			LastName = 'Two'
		);

        insert new List<Contact>{borrower1, borrower2};

        List<Library_Book_Loan__c> newLoans = new List<Library_Book_Loan__c>{
            new Library_Book_Loan__c(Book__c = book.Id, Borrower__c = borrower1.Id, Loan_Start_Date__c = Date.today(), Loan_End_Date__c = Date.today().addDays(10)),
            new Library_Book_Loan__c(Book__c = book.Id, Borrower__c = borrower2.Id, Loan_Start_Date__c = Date.today(), Loan_End_Date__c = Date.today().addDays(14))
        };

        Test.startTest();
        insert newLoans;
        Test.stopTest();

        Library_Book__c updatedBook = [SELECT Id, Available_Copies__c FROM Library_Book__c WHERE Id = :book.Id];
        System.assertEquals(3, updatedBook.Available_Copies__c, 'Available copies should decrease by the number of loans');
    }

    @isTest
    static void testHandleInsert_NoAvailableCopies() {

        Library_Book__c book = new Library_Book__c(Title__c = 'Last Copy', Author__c = 'Final Author', Available_Copies__c = 0);

        insert book;

        Contact borrower = new Contact(
			FirstName = 'Avid',
			LastName = 'Reader'
		);

        insert borrower;

        Library_Book_Loan__c newLoan = new Library_Book_Loan__c(Book__c = book.Id, Borrower__c = borrower.Id, Loan_Start_Date__c = Date.today(), Loan_End_Date__c = Date.today().addDays(5));

        Test.startTest();
        Database.SaveResult sr = Database.insert(newLoan, false);
        Test.stopTest();

        System.assert(!sr.isSuccess(), 'Loan insert should fail due to no available copies');
        System.assert(sr.getErrors().size() > 0, 'Should have at least one error');
        System.assert(sr.getErrors()[0].getMessage().contains(Label.NoCopiesError), 'Error message should indicate no available copies');

        Library_Book__c updatedBook = [SELECT Id, Available_Copies__c FROM Library_Book__c WHERE Id = :book.Id];
        System.assertEquals(0, updatedBook.Available_Copies__c, 'Available copies should not change if the loan fails');
    }

    @isTest
    static void testHandleDelete_SingleLoan() {

        Library_Book__c book = new Library_Book__c(Title__c = 'Returned Book', Author__c = 'Previous Author', Available_Copies__c = 2);

        insert book;

        Contact borrower = new Contact(
			FirstName = 'Returning',
			LastName = 'Reader'
		);

        insert borrower;

        Library_Book_Loan__c oldLoan = new Library_Book_Loan__c(Book__c = book.Id, Borrower__c = borrower.Id, Loan_Start_Date__c = Date.today().addDays(-7), Loan_End_Date__c = Date.today());

        insert oldLoan;

        Test.startTest();
        delete oldLoan;
        Test.stopTest();

        Library_Book__c updatedBook = [SELECT Id, Available_Copies__c FROM Library_Book__c WHERE Id = :book.Id];
        System.assertEquals(2, updatedBook.Available_Copies__c, 'Available copies should be back to its original value after a loan is deleted');
    }

    @isTest
    static void testHandleDelete_MultipleLoansForSameBook() {

        Library_Book__c book = new Library_Book__c(Title__c = 'Multiple Returns', Author__c = 'Often Read Author', Available_Copies__c = 3);

        insert book;

        Contact borrower1 = new Contact(
			FirstName = 'Borrower',
			LastName = 'One'
		);

        Contact borrower2 = new Contact(
			FirstName = 'Borrower',
			LastName = 'Two'
		);

        insert new List<Contact>{borrower1, borrower2};

        List<Library_Book_Loan__c> oldLoans = new List<Library_Book_Loan__c>{
            new Library_Book_Loan__c(Book__c = book.Id, Borrower__c = borrower1.Id, Loan_Start_Date__c = Date.today().addDays(-10), Loan_End_Date__c = Date.today().addDays(-3)),
            new Library_Book_Loan__c(Book__c = book.Id, Borrower__c = borrower2.Id, Loan_Start_Date__c = Date.today().addDays(-5), Loan_End_Date__c = Date.today())
        };

        insert oldLoans;

        Test.startTest();
        delete oldLoans[0];
        Test.stopTest();

        Library_Book__c updatedBook = [SELECT Id, Available_Copies__c FROM Library_Book__c WHERE Id = :book.Id];
        System.assertEquals(2, updatedBook.Available_Copies__c, 'Available copies should increase by the number of deleted loans');
    }

    @isTest
    static void testHandleInsert_MultipleLoansForDifferentBooks() {

        Library_Book__c book1 = new Library_Book__c(Title__c = 'Book A', Author__c = 'Author X', Available_Copies__c = 2);
        Library_Book__c book2 = new Library_Book__c(Title__c = 'Book B', Author__c = 'Author Y', Available_Copies__c = 1);

        insert new List<Library_Book__c>{book1, book2};

        Contact borrower = new Contact(
			FirstName = 'Multi',
			LastName = 'Borrower'
		);

        insert borrower;

        List<Library_Book_Loan__c> newLoans = new List<Library_Book_Loan__c>{
            new Library_Book_Loan__c(Book__c = book1.Id, Borrower__c = borrower.Id, Loan_Start_Date__c = Date.today(), Loan_End_Date__c = Date.today().addDays(7)),
            new Library_Book_Loan__c(Book__c = book2.Id, Borrower__c = borrower.Id, Loan_Start_Date__c = Date.today(), Loan_End_Date__c = Date.today().addDays(10))
        };

        Test.startTest();
        insert newLoans;
        Test.stopTest();


        Library_Book__c updatedBook1 = [SELECT Id, Available_Copies__c FROM Library_Book__c WHERE Id = :book1.Id];
        System.assertEquals(1, updatedBook1.Available_Copies__c, 'Available copies for Book A should decrease by 1');

        Library_Book__c updatedBook2 = [SELECT Id, Available_Copies__c FROM Library_Book__c WHERE Id = :book2.Id];
        System.assertEquals(0, updatedBook2.Available_Copies__c, 'Available copies for Book B should decrease by 1');
    }

    @isTest
    static void testHandleDelete_MultipleLoansForDifferentBooks() {

        Library_Book__c book1 = new Library_Book__c(Title__c = 'Book One', Author__c = 'Writer One', Available_Copies__c = 1);
        Library_Book__c book2 = new Library_Book__c(Title__c = 'Book Two', Author__c = 'Writer Two', Available_Copies__c = 3);

        insert new List<Library_Book__c>{book1, book2};

        Contact borrower = new Contact(
			FirstName = 'Past',
			LastName = 'Borrower'
		);

        insert borrower;

        List<Library_Book_Loan__c> oldLoans = new List<Library_Book_Loan__c>{
            new Library_Book_Loan__c(Book__c = book1.Id, Borrower__c = borrower.Id, Loan_Start_Date__c = Date.today().addDays(-14), Loan_End_Date__c = Date.today().addDays(-7)),
            new Library_Book_Loan__c(Book__c = book2.Id, Borrower__c = borrower.Id, Loan_Start_Date__c = Date.today().addDays(-10), Loan_End_Date__c = Date.today().addDays(-3))
        };

        insert oldLoans;

        Test.startTest();
        delete oldLoans;
        Test.stopTest();

        Library_Book__c updatedBook1 = [SELECT Id, Available_Copies__c FROM Library_Book__c WHERE Id = :book1.Id];
        System.assertEquals(1, updatedBook1.Available_Copies__c, 'Available copies for Book One should return to its original value');

        Library_Book__c updatedBook2 = [SELECT Id, Available_Copies__c FROM Library_Book__c WHERE Id = :book2.Id];
        System.assertEquals(3, updatedBook2.Available_Copies__c, 'Available copies for Book Two should eturn to its original value');
    }
}