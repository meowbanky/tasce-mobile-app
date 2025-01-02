
function  displayAlert(title, position, icon) {
    Swal.fire({
        position: position,
        icon: icon,
        title: title,
        showConfirmButton: false,
        timer: 1500
    });
}
function showSpinner() {
    $('#backdrop').removeClass('hidden');
}


function hideSpinner() {
    $('#backdrop').addClass('hidden');
}
function Sorrtty(table){
    new Tablesort(table);
    table.querySelectorAll('th.sortable').forEach(function(th) {
        th.addEventListener('click', function() {
            var isAscending = th.classList.contains('sort-asc');
            table.querySelectorAll('th.sortable').forEach(function(th) {
                th.classList.remove('sort-asc', 'sort-desc');
            });
            th.classList.toggle('sort-asc', !isAscending);
            th.classList.toggle('sort-desc', isAscending);
        });
    });
}

document.addEventListener('DOMContentLoaded', function () {
    const modal = document.getElementById('topbar-search-modal');
    const searchInput = document.getElementById('search');

    // Check if the modal element exists
    if (!modal) {
        // console.error('Modal element with id "topbar-search-modal" not found');
        return;
    }

    // Check if the search input element exists
    if (!searchInput) {
        // console.error('Search input element with id "search" not found');
        return;
    }

    // Function to focus the input
    function focusSearchInput() {
        searchInput.focus();
        searchInput.value = '';
    }

    // MutationObserver to observe class changes
    const observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
            if (mutation.attributeName === 'class') {
                const isVisible = !modal.classList.contains('hidden');
                if (isVisible) {
                    focusSearchInput();
                }
            }
        });
    });

    // Start observing the modal for attribute changes
    observer.observe(modal, { attributes: true });

    // Event listener for the button to open the modal
    document.querySelector('[data-fc-type="modal"]').addEventListener('click', function () {
        modal.classList.remove('hidden');
        modal.classList.add('fc-modal-open');
    });
});


function showConfirmButton() {
    Swal.fire({
        title: "Are you sure?",
        text: "You won't be able to revert this!",
        icon: "warning",
        showCancelButton: true,
        confirmButtonColor: "#3085d6",
        cancelButtonColor: "#d33",
        confirmButtonText: "Yes, delete it!"
    }).then((result) => {
        if (result.isConfirmed) {
            Swal.fire({
                title: "Deleted!",
                text: "Your file has been deleted.",
                icon: "success"
            });
        }
    });
}