public with sharing class LibraryService {

    public class NoAvailableCopiesException extends Exception {}

    @AuraEnabled
    public static List<Library_Book__c> searchBooks(String searchTerm) {
        List<List<SObject>> searchResults = [
            FIND :('*' + searchTerm + '*') IN ALL FIELDS
            RETURNING Library_Book__c (Id, Title__c, Author__c, Available_Copies__c)
        ];
        return (List<Library_Book__c>) searchResults[0];
    }

    @AuraEnabled
    public static void loanBook(Id bookId, Id borrowerId, Integer numberOfCopies, Date loanEndDate) {
        if (numberOfCopies <= 0) {
            throw new NoAvailableCopiesException(Label.NoCopiesError);
        }

        Library_Book_Loan__c newLoan = new Library_Book_Loan__c(
            Borrower__c = borrowerId,
            Book__c = bookId,
            Loan_Start_Date__c = Date.today(),
            Loan_End_Date__c = loanEndDate
        );

        insert newLoan;
    }
}