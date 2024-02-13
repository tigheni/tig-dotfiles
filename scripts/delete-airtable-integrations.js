while (true) {
  const listItem = document.querySelector(
    "[data-testid^=oauth-access-token-list-item]",
  );
  listItem.click();

  await new Promise((resolve) => setTimeout(resolve, 1000));

  const deleteButton = document.querySelector(
    "[data-testid=destroy-oauth-access-token]",
  );
  deleteButton.click();

  await new Promise((resolve) => setTimeout(resolve, 400));

  const confirmDeleteButton = document.querySelector(
    "[data-testid=confirmation-modal-confirm-button]",
  );
  confirmDeleteButton.click();

  await new Promise((resolve) => setTimeout(resolve, 1000));
}
