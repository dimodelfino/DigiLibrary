trigger LibraryBookLoanTrigger on Library_Book_Loan__c (before insert, before delete) {

    if (Trigger.isInsert) {
        LibraryBookLoanTriggerHandler.handleInsert(Trigger.new);
    } else if (Trigger.isDelete) {
        LibraryBookLoanTriggerHandler.handleDelete(Trigger.oldMap);
    }
}