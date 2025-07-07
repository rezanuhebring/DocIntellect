// /home/user/document_classifier/static/js/dashboard.js

$(document).ready(function() {
    let categoryChart;

    // --- UNCHANGED FUNCTIONS: updateStats, updateTable ---
    function updateStats(stats) { /* ... same as before ... */ }
    function updateTable(documents) { /* ... same as before ... */ }

    function fetchData() {
        $.getJSON('/api/stats', function(data) { updateStats(data); });
        $.getJSON('/api/documents', function(data) { updateTable(data); });
    }

    // --- NEW FUNCTION to load scan locations ---
    function loadScanLocations() {
        const select = $('#scan-path-select');
        const scanBtn = $('#scan-btn');
        
        $.getJSON('/api/scan_locations', function(locations) {
            select.empty();
            if (locations.length > 0) {
                locations.forEach(loc => {
                    select.append(`<option value="${loc}">${loc}</option>`);
                });
                select.prop('disabled', false);
                scanBtn.prop('disabled', false);
            } else {
                select.append('<option>No scannable drives found in docker-compose.yml</option>');
            }
        }).fail(function() {
            select.empty().append('<option>Error loading locations</option>');
        });
    }

    // --- MODIFIED: Scan button click handler ---
    $('#scan-btn').on('click', function() {
        const btn = $(this);
        const selectedPath = $('#scan-path-select').val();

        if (!selectedPath) {
            $('#scan-status').text('Please select a directory to scan.').addClass('text-danger');
            return;
        }

        btn.prop('disabled', true).html('<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Scanning...');
        $('#scan-status').text(`Scan initiated for ${selectedPath}. This may take a while...`).removeClass('text-danger');

        // Use $.ajax to easily send JSON data
        $.ajax({
            url: '/api/scan',
            type: 'POST',
            contentType: 'application/json',
            data: JSON.stringify({ path: selectedPath }),
            success: function(data) {
                $('#scan-status').text(data.message);
            },
            error: function(jqXHR) {
                const errorMsg = jqXHR.responseJSON ? jqXHR.responseJSON.error : 'Unknown error occurred.';
                $('#scan-status').text(`Error: ${errorMsg}`).addClass('text-danger');
            },
            complete: function() {
                btn.prop('disabled', false).html('<i class="bi bi-search"></i> Scan Selected Directory');
            }
        });
    });

    // --- INITIALIZATION ---
    loadScanLocations(); // Load the dropdown on page load
    fetchData();
    setInterval(fetchData, 5000);

    /* Helper functions copied from original for completeness */
    function updateStats(stats) {
        $('#total-docs').text(stats.total_documents);
        const ctx = $('#category-chart');
        const chartData = {
            labels: Object.keys(stats.by_category),
            datasets: [{
                label: 'Documents',
                data: Object.values(stats.by_category),
                backgroundColor: ['rgba(255, 99, 132, 0.7)', 'rgba(54, 162, 235, 0.7)', 'rgba(255, 206, 86, 0.7)', 'rgba(75, 192, 192, 0.7)', 'rgba(153, 102, 255, 0.7)', 'rgba(255, 159, 64, 0.7)']
            }]
        };
        if (categoryChart) { categoryChart.data = chartData; categoryChart.update(); }
        else { categoryChart = new Chart(ctx, { type: 'doughnut', data: chartData, options: { responsive: true, plugins: { legend: { position: 'top' } } } }); }
    }
    function updateTable(documents) {
        const tableBody = $('#documents-table');
        tableBody.empty();
        if (documents.length === 0) { tableBody.append('<tr><td colspan="5" class="text-center">No documents processed yet.</td></tr>'); return; }
        documents.forEach(doc => {
            let confidenceBadge = 'secondary';
            if (doc.confidence_score > 0.8) confidenceBadge = 'success';
            else if (doc.confidence_score > 0.5) confidenceBadge = 'warning';
            tableBody.append(`<tr><td><i class="bi bi-file-earmark-text"></i> ${doc.filename.split('/').pop()}</td><td>${doc.predicted_category}</td><td><span class="badge text-bg-${confidenceBadge}">${(doc.confidence_score * 100).toFixed(1)}%</span></td><td>${doc.language.toUpperCase()}</td><td>${new Date(doc.modified_date).toLocaleString()}</td></tr>`);
        });
    }
});