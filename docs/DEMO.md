# Functional demonstration

1. Follow the README to create the MySQL database, migrate, create an administrator, and start the API and Flutter application.
2. Register an employee. Confirm that the dashboard loads and staff management is unavailable. Sign out and sign back in.
3. Create a customer with name and phone; search for them, change the phone and reopen the record.
4. Create a device and select that customer. Edit its model.
5. Create a repair order for the device. Enter the reported problem, select an employee, set the price and save. Check the generated repair number.
6. Open the order details, change the status to `repairing`, then `completed`. Check both events in repair history. Filter the order list by completed status and refresh the dashboard.
7. Create an inventory part, edit its quantity, search for it and delete it using the confirmation dialog.
8. Edit your profile and restart the application to check session restoration. Disconnect the API and verify an error with a retry option rather than a loading spinner forever.
9. Sign in as the administrator. Create another staff member, edit their role and delete their account. Verify an employee token receives HTTP 403 on `/api/users` using Postman.
10. Attempt to delete the customer/device while linked records exist. Expect HTTP 409. Delete the repair order, device and customer in that order. Verify empty-list messages.
11. Sign out and attempt to open a protected route. Expect the login screen. The revoked token must receive HTTP 401 in Postman.

Automated backend tests cover authentication, privilege escalation prevention, all resource CRUD, role enforcement, status history, filters, dashboard counts, validation and deletion conflicts. Widget tests cover route protection, validation and rendered UI captures. A real Android/MySQL demonstration still requires your emulator/device and database credentials.
