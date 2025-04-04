public with sharing class LibraryBookLoanTriggerHandler {

    public static void handleInsert(List<Library_Book_Loan__c> newLoans) {
        updateBookCopies(newLoans, null);
    }

    public static void handleDelete(Map<Id, Library_Book_Loan__c> oldLoans) {
        updateBookCopies(null, oldLoans);
    }

    private static void updateBookCopies(List<Library_Book_Loan__c> newLoans, Map<Id, Library_Book_Loan__c> oldLoans) {
        Set<Id> bookIds = new Set<Id>();

        if (newLoans != null) {
            for (Library_Book_Loan__c loan : newLoans) {
                bookIds.add(loan.Book__c);
            }
        }
        if (oldLoans != null) {
            for (Library_Book_Loan__c loan : oldLoans.values()) {
                bookIds.add(loan.Book__c);
            }
        }

        Map<Id, Library_Book__c> bookMap = new Map<Id, Library_Book__c>([
            SELECT Id, Available_Copies__c FROM Library_Book__c WHERE Id IN :bookIds
        ]);

        Map<Id, Library_Book__c> booksToUpdate = new Map<Id, Library_Book__c>();

        if (newLoans != null) {
            for (Library_Book_Loan__c loan : newLoans) {
                Library_Book__c book = bookMap.get(loan.Book__c);
                if (book != null && book.Available_Copies__c > 0) {
                    book.Available_Copies__c -= 1;
                    booksToUpdate.put(book.Id, book);
                } else {
                    loan.addError(Label.NoCopiesError);
                }
            }
        }

        if (oldLoans != null) {
            for (Library_Book_Loan__c loan : oldLoans.values()) {
                Library_Book__c book = bookMap.get(loan.Book__c);
                if (book != null) {
                    book.Available_Copies__c += 1;
                    booksToUpdate.put(book.Id, book);
                }
            }
        }

        if (!booksToUpdate.isEmpty()) {
            try {
                update booksToUpdate.values();
            } catch (DmlException e) {
                System.debug('Error updating books: ' + e.getMessage());
            }
        }
    }
}