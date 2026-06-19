/**
 * TripMeAI Genesis Core Logic
 * Handles micro-interactions, active state management, and terminal simulations.
 */

document.addEventListener('DOMContentLoaded', () => {
    // 1. Sidebar Active State Sync
    const currentPath = window.location.pathname;
    const navLinks = document.querySelectorAll('nav a');
    
    navLinks.forEach(link => {
        const href = link.getAttribute('href');
        if (currentPath === href || (href !== '/' && currentPath.startsWith(href))) {
            link.classList.add('nav-active');
            // Add a sub-glow to the active icon
            const icon = link.querySelector('svg');
            if (icon) icon.classList.add('text-white');
        }
    });

    // 2. Terminal Auto-Scroll (for Pipeline logs)
    const terminalLogs = document.getElementById('terminal-logs');
    if (terminalLogs) {
        const observer = new MutationObserver(() => {
            terminalLogs.scrollTop = terminalLogs.scrollHeight;
        });
        observer.observe(terminalLogs, { childList: true });
    }

    // 3. Status Notification System (Toast Simulation)
    window.showToast = (message, type = 'info') => {
        const toast = document.createElement('div');
        toast.className = `fixed bottom-8 right-8 px-6 py-4 rounded-xl shadow-2xl z-50 transform translate-y-20 transition-all duration-300 font-bold text-xs uppercase tracking-widest flex items-center gap-3 ${
            type === 'error' ? 'bg-red-600 text-white' : 'bg-gray-900 text-white'
        }`;
        
        toast.innerHTML = `
            <div class="w-1.5 h-1.5 rounded-full ${type === 'error' ? 'bg-white' : 'bg-indigo-400'} animate-pulse"></div>
            ${message}
        `;
        
        document.body.appendChild(toast);
        
        // Trigger animation
        setTimeout(() => toast.classList.remove('translate-y-20'), 100);
        
        // Remove
        setTimeout(() => {
            toast.classList.add('opacity-0', 'translate-y-4');
            setTimeout(() => toast.remove(), 300);
        }, 4000);
    };

    // 4. Data Table Search (Client-Side Filter for small lists)
    const tableSearch = document.getElementById('table-search');
    if (tableSearch) {
        tableSearch.addEventListener('input', (e) => {
            const term = e.target.value.toLowerCase();
            const rows = document.querySelectorAll('tbody tr');
            
            rows.forEach(row => {
                const text = row.textContent.toLowerCase();
                row.style.display = text.includes(term) ? '' : 'none';
            });
        });
    }
});
