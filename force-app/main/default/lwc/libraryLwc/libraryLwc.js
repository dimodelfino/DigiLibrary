import { LightningElement, track, wire } from 'lwc';
import searchBooks from '@salesforce/apex/LibraryService.searchBooks';
import loanBook from '@salesforce/apex/LibraryService.loanBook';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import BookLendedSuccess from "@salesforce/label/c.BookLendedSuccess";
import SelectBorrowerError from "@salesforce/label/c.SelectBorrowerError";
import SelectDateError from "@salesforce/label/c.SelectDateError";


export default class LibraryLwc extends LightningElement {
    searchTerm = '';
    books = [];
    error;
    selectedBorrowerId = null;
    loanEndDate = null;

    get isSearchDisabled() {
        return this.searchTerm === '';
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
    }

    handleLoanEndDateChange(event) {
        const bookId = event.target.dataset.id;
        const selectedBook = this.books.find(book => book.Id === bookId);
        if (selectedBook) {
            selectedBook.loanEndDate = event.target.value;
            this.books = [...this.books];
        }
    }

    clearValues(){
        this.searchTerm = '';
        this.books = [];
        this.error = undefined;
        this.selectedBorrowerId = null;
        this.loanEndDate = null;
        this.template.querySelector('lightning-record-picker').clearSelection();
    }


    handleSearch() {
        searchBooks({ searchTerm: this.searchTerm })
            .then(result => {
                this.books = result;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error.body.message;
                this.handleToastMessages('Error', error.body.message, 'error');
                this.books = [];
            });
    }

    handleBorrowerSelect(event) {
        const bookId = event.target.dataset.id;
        const selectedBook = this.books.find(book => book.Id === bookId);
        if (selectedBook) {
            selectedBook.selectedBorrowerId = event.detail.recordId;
            this.books = [...this.books];
        }
    }

    handleLoan(event) {
        const bookId = event.target.dataset.id;
        const selectedBook = this.books.find(book => book.Id === bookId);
        const availableCopies = event.target.dataset.availableCopies;

        if (!selectedBook.selectedBorrowerId) {
            this.handleToastMessages('Error', SelectBorrowerError, 'error');
            return;
        }

        if (!selectedBook.loanEndDate) {
            this.handleToastMessages('Error', SelectDateError, 'error');
            return;
        }

        loanBook({ bookId: bookId, borrowerId: selectedBook.selectedBorrowerId, numberOfCopies: availableCopies, loanEndDate: selectedBook.loanEndDate })
        .then(() => {
            this.clearValues();
            this.handleToastMessages('Success', BookLendedSuccess, 'success');
        })
        .catch(error => {
            const errorMessage = error.body?.message ? error.body?.message : error.body?.pageErrors[0]?.message;
            this.handleToastMessages('Error', errorMessage, 'error');
        });
    }

    handleToastMessages(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );

    }
}
