use crate::style;
use crate::Message;

pub const SEARCH_INPUT_ID: &str = "search_input";

pub fn view(query: &String) -> iced::Element<'static, Message> {
    return iced::widget::row![
        iced::widget::container(iced::widget::text("󰍉 ").size(1.3 * style::REM)).padding(
            iced::Padding::from([0.2 * style::REM, -0.5 * style::REM, 0., 0.])
        ),
        iced::widget::text_input("Search", query)
            .id(iced::widget::text_input::Id::new(SEARCH_INPUT_ID))
            .on_input(Message::Search)
            .size(1. * style::REM)
            .style(style())
    ]
    .padding(iced::Padding::from([0.8 * style::REM, 1. * style::REM]))
    .into();
}

fn style() -> iced::theme::TextInput {
    return iced::theme::TextInput::Custom(Box::new(Style {}));
}

pub struct Style {}

impl iced::widget::text_input::StyleSheet for Style {
    type Style = iced::Theme;

    fn active(&self, _style: &Self::Style) -> iced::widget::text_input::Appearance {
        return iced::widget::text_input::Appearance {
            background: iced::Background::Color(iced::color!(0x000000, 0.)),
            border_radius: iced::BorderRadius::from(0.),
            border_width: 0.,
            border_color: iced::color!(0x000000, 0.),
            icon_color: iced::color!(0xf3f3f3, 1.),
        };
    }

    fn focused(&self, style: &Self::Style) -> iced::widget::text_input::Appearance {
        return self.active(style);
    }

    fn disabled(&self, style: &Self::Style) -> iced::widget::text_input::Appearance {
        return self.active(style);
    }

    fn placeholder_color(&self, _style: &Self::Style) -> iced::Color {
        return iced::color!(0xf3f3f3, 1.);
    }

    fn value_color(&self, _style: &Self::Style) -> iced::Color {
        return iced::color!(0xffffff, 1.);
    }

    fn disabled_color(&self, _style: &Self::Style) -> iced::Color {
        return iced::color!(0xfafafa, 1.);
    }

    fn selection_color(&self, _style: &Self::Style) -> iced::Color {
        return iced::color!(0x1b1b1b, 1.);
    }
}