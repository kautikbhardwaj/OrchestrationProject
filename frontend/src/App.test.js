import { render, screen } from '@testing-library/react';
import App from './App';

jest.mock('./components/Home', () => () => null);

test('renders the application heading', () => {
  render(<App />);
  expect(screen.getByRole('heading', { name: /welcome/i })).toBeInTheDocument();
});
