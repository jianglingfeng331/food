"""初始迁移：创建所有基础表

Revision ID: 001_initial
Create Date: 2026-08-04
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "001_initial"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("name", sa.String(), nullable=False),
        sa.Column("avatar", sa.String(), default="🙂"),
        sa.Column("current_weight", sa.Float(), default=0),
        sa.Column("target_weight", sa.Float(), default=0),
        sa.Column("height", sa.Float(), default=0),
        sa.Column("password_hash", sa.String(), default=""),
        sa.Column("partner_id", sa.String(), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "records",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("type", sa.String(), nullable=False),
        sa.Column("name", sa.String(), default=""),
        sa.Column("calories", sa.Float(), default=0),
        sa.Column("amount", sa.Float(), default=0),
        sa.Column("unit", sa.String(), default=""),
        sa.Column("time", sa.String(), default=""),
        sa.Column("created_at", sa.DateTime(), default=sa.func.now()),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "stickers",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), sa.ForeignKey("users.id"), nullable=False, index=True),
        sa.Column("name", sa.String(), default=""),
        sa.Column("image_b64", sa.Text(), default=""),
        sa.Column("image_path", sa.String(), default=""),
        sa.Column("created_at", sa.DateTime(), default=sa.func.now()),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_table(
        "pk_weeks",
        sa.Column("id", sa.String(), nullable=False),
        sa.Column("user_id", sa.String(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("partner_id", sa.String(), nullable=True),
        sa.Column("start_date", sa.String(), default=""),
        sa.Column("days", sa.Integer(), default=0),
        sa.PrimaryKeyConstraint("id"),
    )


def downgrade() -> None:
    op.drop_table("pk_weeks")
    op.drop_table("stickers")
    op.drop_table("records")
    op.drop_table("users")
