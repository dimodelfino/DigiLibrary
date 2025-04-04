@isTest
private class LibraryServiceTest {

    @testSetup
    static void setupTestData() {
        // Create test books
        List<Library_Book__c> books = new List<Library_Book__c>{
            new Library_Book__c(Title__c = 'The Great Gatsby', Author__c = 'F. Scott Fitzgerald', Available_Copies__c = 3),
            new Library_Book__c(Title__c = 'One Hundred Years of Solitude', Author__c = 'Harper Lee', Available_Copies__c = 5),
            new Library_Book__c(Title__c = 'The Great Escape', Author__c = 'Someone Else', Available_Copies__c = 1)
        };
        insert books;
    }

    @isTest
    static void testSearchBooks_Found() {

        String searchTerm = 'The Great';
        List<Library_Book__c> books = [SELECT Id FROM Library_Book__c WHERE Title__c LIKE '%Great%'];

        Test.setFixedSearchResults(new List<Id>{ books[0].Id, books[1].Id });

        Test.startTest();
        List<Library_Book__c> results = LibraryService.searchBooks(searchTerm);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should find two book matching the search term');
        System.assertEquals('The Great Gatsby', results[0].Title__c, 'The found book should have the correct title');
    }

    @isTest
    static void testSearchBooks_NotFound() {

        String searchTerm = '1984';

        Test.startTest();
        List<Library_Book__c> results = LibraryService.searchBooks(searchTerm);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should not find any books for the given search term');
    }

    @isTest
    static void testLoanBook_Success() {
        List<Library_Book__c> books = [SELECT Id FROM Library_Book__c WHERE Title__c LIKE 'One Hundred%'];
        Test.setFixedSearchResults(new List<Id>{ books[0].Id});

        Library_Book__c book = LibraryService.searchBooks('One Hundred')[0];
        Contact borrower = new Contact(
			FirstName = 'Test',
			LastName = 'Borrower'
		);

        insert borrower;

        Date loanEndDate = Date.today().addDays(14);
        Integer numberOfCopies = 1;

        Test.startTest();
        LibraryService.loanBook(book.Id, borrower.Id, numberOfCopies, loanEndDate);
        Test.stopTest();

        List<Library_Book_Loan__c> loans = [SELECT Id, Book__c, Borrower__c, Loan_End_Date__c FROM Library_Book_Loan__c WHERE Book__c = :book.Id AND Borrower__c = :borrower.Id];
        System.assertEquals(1, loans.size(), 'A new loan record should be created');
        System.assertEquals(book.Id, loans[0].Book__c, 'The loan should be for the correct book');
        System.assertEquals(borrower.Id, loans[0].Borrower__c, 'The loan should be for the correct borrower');
        System.assertEquals(loanEndDate, loans[0].Loan_End_Date__c, 'The loan end date should be correct');
    }

    @isTest
    static void testLoanBook_ZeroCopies() {
        Library_Book__c book = new Library_Book__c(Title__c = 'The Hitchhiker\'s Guide to the Galaxy', Author__c = 'Douglas Adams', Available_Copies__c = 0);

        insert book;

        Contact borrower = new Contact(
            FirstName = 'Test',
            LastName = 'Borrower'
        );

        insert borrower;

        Date loanEndDate = Date.today().addDays(7);

        Test.startTest();
        try {
            LibraryService.loanBook(book.Id, borrower.Id, (Integer)book.Available_Copies__c, loanEndDate);
        } catch (LibraryService.NoAvailableCopiesException e) {
            System.assertEquals(Label.NoCopiesError, e.getMessage(), 'The exception message should be correct');
        }
        Test.stopTest();

        List<Library_Book_Loan__c> loans = [SELECT Id FROM Library_Book_Loan__c WHERE Book__c = :book.Id AND Borrower__c = :borrower.Id];
        System.assertEquals(0, loans.size(), 'No loan record should be created');
    }
}