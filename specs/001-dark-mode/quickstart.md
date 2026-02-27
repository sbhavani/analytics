# Quickstart: Dark Mode

## How to Use Dark Mode

### For Users

1. Navigate to **Settings** → **Preferences**
2. Scroll to the **Appearance** section
3. Select your preferred theme:
   - **Follow System Theme** - Automatically matches your device's setting
   - **Light** - Always use light theme
   - **Dark** - Always use dark theme
4. Click **Change theme** to save

Your preference will be remembered across sessions.

### For Developers

#### Running the Application

```bash
# Start the Phoenix server
mix phx.server

# Or with Docker
docker-compose up
```

#### Theme Files Location

| Purpose | File |
|---------|------|
| User model | `lib/plausible/auth/user.ex` |
| Theme options | `lib/plausible/themes.ex` |
| Settings controller | `lib/plausible_web/controllers/settings_controller.ex` |
| Server-side script | `lib/plausible_web/components/layout.ex` |
| Settings template | `lib/plausible_web/templates/settings/preferences.html.heex` |
| React context | `assets/js/dashboard/theme-context.tsx` |
| CSS styles | `assets/css/app.css` |

#### Testing Theme Changes

1. **Manual testing**: Visit `/settings/preferences` and change theme
2. **Browser devtools**: Check for `dark` class on `<html>` element
3. **System preference**: Change OS dark mode setting and refresh

#### Adding Dark Mode to New Components

Use TailwindCSS dark mode classes:

```html
<div class="bg-white dark:bg-gray-900 text-gray-900 dark:text-white">
  Content here
</div>
```

Or use the React theme context:

```tsx
import { useTheme } from './theme-context'

function MyComponent() {
  const { dark } = useTheme()

  return (
    <div className={dark ? 'dark-styles' : 'light-styles'}>
      Content
    </div>
  )
}
```
